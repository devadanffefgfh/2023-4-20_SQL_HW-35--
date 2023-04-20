--1找出和最貴的產品同類別的所有產品
SELECT *FROM Products
WHERE CategoryID = (
	select top 1
		CategoryID
	from Products
	order by UnitPrice DESC
)

--2找出和最貴的產品同類別最便宜的產品
SELECT top 1 * FROM Products p
WHERE p.CategoryID = (
	select top 1
		CategoryID
	from Products
	order by UnitPrice DESC
)
order by UnitPrice

--3計算出上面類別最貴和最便宜的兩個產品的價差
SELECT MaxPriceProduct.UnitPrice - MinPriceProduct.UnitPrice
FROM (
    SELECT TOP 1 *
    FROM Products
    WHERE CategoryID = (
        SELECT TOP 1 CategoryID
        FROM Products
        ORDER BY UnitPrice DESC
    )
    ORDER BY UnitPrice 
) AS MinPriceProduct
JOIN (
    SELECT TOP 1 *
    FROM Products
    WHERE CategoryID = (
        SELECT TOP 1 CategoryID
        FROM Products
        ORDER BY UnitPrice DESC
    )
    ORDER BY UnitPrice DESC
) AS MaxPriceProduct
ON MinPriceProduct.CategoryID = MaxPriceProduct.CategoryID

--4找出沒有訂過任何商品的客戶所在的城市的所有客戶
SELECT
	c.CompanyName
FROM Customers c
WHERE c.City = (
	SELECT 
		c.City	
	FROM Customers c
	LEFT JOIN Orders o ON c.CustomerID=o.CustomerID
	WHERE o.CustomerID IS NULL
	ORDER BY c.City
	OFFSET 1 ROWS
	FETCH NEXT 1 ROWS ONLY) 
or c.City = (
	SELECT 	
		c.City
	FROM Customers c
	LEFT JOIN Orders o ON c.CustomerID=o.CustomerID
	WHERE o.CustomerID IS NULL
	ORDER BY c.City
	OFFSET 0 ROWS
	FETCH NEXT 1 ROWS ONLY)

--5 找出第 5 貴跟第 8 便宜的產品的產品類別

SELECT 
	c.CategoryName
FROM Categories c
WHERE c.CategoryID = (
	SELECT
		p.CategoryID
	FROM Products p
	order by p.UnitPrice 
	OFFSET 7 ROWS
	FETCH NEXT 1 ROWS ONLY) or 
c.CategoryID = (
	SELECT
		p.CategoryID
	FROM Products p
	order by p.UnitPrice DESC
	OFFSET 4 ROWS
	FETCH NEXT 1 ROWS ONLY
)

--6 找出誰買過第 5 貴跟第 8 便宜的產品


SELECT DISTINCT
	c.CompanyName
FROM Products p
JOIN [Order Details] od ON od.ProductID = p.ProductID
JOIN Orders o ON o.OrderID =od.OrderID
JOIN Customers c ON c.CustomerID = o.CustomerID
WHERE p.ProductID = (
SELECT
	p.ProductID
FROM Products p
order by p.UnitPrice DESC
OFFSET 4 ROWS
FETCH NEXT 1 ROWS ONLY
)or p.ProductID = (
SELECT
	p.ProductID
FROM Products p
order by p.UnitPrice 
OFFSET 7 ROWS
FETCH NEXT 1 ROWS ONLY)

--7 找出誰賣過第 5 貴跟第 8 便宜的產品
SELECT *FROM Products
SELECT *FROM Suppliers
SELECT
	p.SupplierID
FROM Products p
order by p.UnitPrice DESC
OFFSET 4 ROWS
FETCH NEXT 1 ROWS ONLY

SELECT
	p.SupplierID
FROM Products p
order by p.UnitPrice 
OFFSET 7 ROWS
FETCH NEXT 1 ROWS ONLY

SELECT DISTINCT
	s.CompanyName
FROM Products p
join Suppliers s ON s.SupplierID = p.SupplierID
WHERE s.SupplierID =(
	SELECT
		p.SupplierID
	FROM Products p
	order by p.UnitPrice DESC
	OFFSET 4 ROWS
	FETCH NEXT 1 ROWS ONLY) or
s.SupplierID = (
	SELECT
		p.SupplierID
	FROM Products p
	order by p.UnitPrice 
	OFFSET 7 ROWS
	FETCH NEXT 1 ROWS ONLY
)

--8 找出 13 號星期五的訂單 (惡魔的訂單)
select
	*
from Orders
where DATEPART(WEEKDAY,OrderDate) =6 and (DATEPART(DAY,OrderDate)=13);

-- 9找出誰訂了惡魔的訂單
SELECT
	c.CompanyName
FROM Orders o 
inner join Customers c ON c.CustomerID = o.CustomerID
where DATEPART(WEEKDAY,OrderDate) =6 and (DATEPART(DAY,OrderDate)=13);
-- 10找出惡魔的訂單裡有什麼產品
select
	p.ProductName
from Orders o
inner join [Order Details] od ON od.OrderID = o.OrderID
join Products p ON p.ProductID = od.ProductID
where DATEPART(WEEKDAY,OrderDate) =6 and (DATEPART(DAY,OrderDate)=13);

-- 11列出從來沒有打折 (Discount) 出售的產品
select distinct
	p.ProductName
from [Order Details] od
join Products p ON p.ProductID = od.ProductID
where od.Discount = 0
order by p.ProductName;
-- 12列出購買非本國的產品的客戶
select distinct
	c.CompanyName
from Customers c
join Orders o ON o.CustomerID = c.CustomerID 
join [Order Details] od ON od.OrderID = o.OrderID
join Products p ON p.ProductID = od.ProductID
join Suppliers s ON s.SupplierID = p.SupplierID
where s.Country!=c.Country

-- 13列出在同個城市中有公司員工可以服務的客戶
select distinct
	c.CompanyName
from Customers c
join Orders o ON o.CustomerID = c.CustomerID
join Employees em ON em.EmployeeID = o.EmployeeID
where c.City = em.City;
-- 14列出那些產品沒有人買過
select distinct
	p.ProductName
from Products p
where p.ProductID NOT IN(
	select distinct
		od.ProductID
	from [Order Details] od
)
----------------------------------------------------------------------------------------
--15 列出所有在每個月月底的訂單
select 
	*
from Orders o
where o.OrderDate = EOMONTH(o.OrderDate) 
-- 16列出每個月月底售出的產品
select
*
from Products p 
join [Order Details] od ON od.ProductID = p.ProductID
join Orders o ON o.OrderID = od.OrderID
where EXISTS (
	select 
		ods.ProductID
	from Orders o2
	join [Order Details] ods  ON  od.OrderID = o2.OrderID
	where o2.OrderDate = EOMONTH(o2.OrderDate) and
	ods.ProductID = p.ProductID
);

-- 17找出有買過最貴的三個產品中的任何一個的前三個大客戶
select top 3
	c.CompanyName, 
	c.CustomerID,
	
	
	SUM(od.UnitPrice*od.Quantity*(1-od.Discount)) as totalmoney
from Customers c
join Orders o ON o.CustomerID = c.CustomerID
join [Order Details] od ON od.OrderID = o.OrderID
join Products p ON p.ProductID = od.ProductID
where od.ProductID in (
	select top 3
	p.ProductID
	from Products p
	order by p.UnitPrice DESC
)
group by c.CompanyName,c.CustomerID
order by totalmoney desc;


-- 18找出有買過銷售金額前三高個產品的前三個大客戶


select top 3
	c.CompanyName,
	SUM(od.UnitPrice*od.Quantity*(1-od.Discount)) as totalmoney
from Customers c
join Orders o ON o.CustomerID = c.CustomerID
join [Order Details] od ON od.OrderID = o.OrderID
join Products p ON p.ProductID = od.ProductID
where c.CustomerID in(
	select 
		c.CustomerID
	from Customers c
	join Orders o ON o.CustomerID = c.CustomerID
	join [Order Details] od ON od.OrderID = o.OrderID
	join Products p ON p.ProductID = od.ProductID

	where od.ProductID in (
		select top 3
			od.ProductID	
		from [Order Details] od
		join Products p ON p.ProductID = od.ProductID 
		join Orders o ON o.OrderID = od.OrderID
		join Customers c ON c.CustomerID = o.CustomerID
		group by od.ProductID
		order by SUM(p.UnitPrice*od.Quantity*(1-od.Discount)) DESC
	
	)
	group by c.CustomerID
)
group by c.CompanyName,c.CustomerID
order by totalmoney desc;

-- 19找出有買過銷售金額前三高個產品所屬類別的前三個大客戶
select top 3
	c.CompanyName,
	c.CustomerID,
	
	SUM(od.UnitPrice*od.Quantity*(1-od.Discount)) as totalmoney
from Customers c
join Orders o ON o.CustomerID = c.CustomerID
join [Order Details] od ON od.OrderID = o.OrderID
join Products p ON p.ProductID = od.ProductID
join Categories cate ON cate.CategoryID = p.CategoryID
where c.CustomerID in(
	select 
		c.CustomerID
	from Customers c
	join Orders o ON o.CustomerID = c.CustomerID
	join [Order Details] od ON od.OrderID = o.OrderID
	join Products p ON p.ProductID = od.ProductID
	join Categories cate ON cate.CategoryID = p.CategoryID
	where p.CategoryID in (
		select top 3
			p.CategoryID	
		from [Order Details] od
		join Products p ON p.ProductID = od.ProductID 
		join Orders o ON o.OrderID = od.OrderID
		join Customers c ON c.CustomerID = o.CustomerID
		group by p.CategoryID
		order by SUM(p.UnitPrice*od.Quantity) DESC
	
	)
	group by c.CustomerID
)
group by c.CompanyName,c.CustomerID 
order by totalmoney desc;

-- 20列出消費總金額高於所有客戶平均消費總金額的客戶的名字，以及客戶的消費總金額
with t1 as(
	select
	
		c.CompanyName,
		c.CustomerID,
		SUM(od.UnitPrice*od.Quantity*(1-od.Discount)) as totalmoney

	from Customers c
	join Orders o ON o.CustomerID = c.CustomerID
	join [Order Details] od ON od.OrderID = o.OrderID
	join Products p ON p.ProductID = od.ProductID

	group by c.CompanyName,c.CustomerID
	
)
select
*
from t1
where totalmoney > (select AVG(totalmoney) from t1 )
order by totalmoney desc;
-- 21列出最熱銷的產品，以及被購買的總金額
with t1 as(
	select top 1
		p.ProductID,
	
		SUM(od.Quantity) as Total
	from Customers c
	join Orders o ON o.CustomerID = c.CustomerID
	join [Order Details] od ON od.OrderID = o.OrderID
	join Products p ON p.ProductID = od.ProductID
	group by p.ProductID
	order by Total desc

)
select 
	od.ProductID,
	p.ProductName,
	SUM(od.UnitPrice*od.Quantity*(1-od.Discount)) as totalmoney
from [Order Details] od
join Products p ON p.ProductID = od.ProductID
where od.ProductID in (
	select  
		ProductID
	from t1
) 
group by od.ProductID,p.ProductName;




-- 22列出最少人買的產品
with t1 as(
	select top 1
		p.ProductID,
		SUM(od.Quantity) as total
	from Products p
	join [Order Details] od ON od.ProductID = p.ProductID
	join Orders o ON o.OrderID = od.OrderID
	join Customers c ON c.CustomerID = o.CustomerID
	group by p.ProductID
	order by total ASC
)
select
	p.ProductName,
	p.ProductID,
	t.total
from Products p
join t1 t on t.ProductID = p.ProductID
where p.ProductID in (
	select
		ProductID
	from t1
)


-- 23列出最沒人要買的產品類別 (Categories)
with t1 as(
	select top 1
		p.ProductID,
		SUM(od.Quantity) as total
	from Products p
	join [Order Details] od ON od.ProductID = p.ProductID
	join Orders o ON o.OrderID = od.OrderID
	join Customers c ON c.CustomerID = o.CustomerID
	group by p.ProductID
	order by total ASC
)
select
	p.ProductName,
	p.ProductID,
	t.total,
	cate.CategoryName
from Products p
join t1 t on t.ProductID = p.ProductID
join Categories cate ON cate.CategoryID = p.CategoryID
where p.ProductID in (
	select
		ProductID
	from t1
);

-- 24列出跟銷售最好的供應商買最多金額的客戶與購買金額 (含購買其它供應商的產品)
with t1 as(
	select  top 1
		s.SupplierID,
		SUM(od.UnitPrice*od.Quantity*(1-od.Discount)) as totalmoney
	from Products p
	join Suppliers s on s.SupplierID = p.SupplierID
	join [Order Details] od on od.ProductID = p.ProductID
	group by s.SupplierID
	order by totalmoney DESC
)
select top 1
	c.CompanyName,
	c.CustomerID,
	SUM(od.UnitPrice*od.Quantity*(1-od.Discount)) as  customertotalmoney
from Customers c
join Orders o on o.CustomerID = c.CustomerID
join [Order Details] od on od.OrderID = o.OrderID
join Products p on p.ProductID = od.ProductID
where p.SupplierID in (
	select
		t.SupplierID
	from t1 t
)
group by c.CompanyName,c.CustomerID
order by customertotalmoney DESC
-- 25列出跟銷售最好的供應商買最多金額的客戶與購買金額 (不含購買其它供應商的產品)
WITH TopSupplier AS (
    SELECT top 1
        S.SupplierID,
        SUM(OD.UnitPrice * OD.Quantity * (1 - OD.Discount)) AS TotalSales
    FROM Suppliers S
    JOIN Products P ON S.SupplierID = P.SupplierID
    JOIN [Order Details] OD ON P.ProductID = OD.ProductID
    GROUP BY S.SupplierID
    ORDER BY TotalSales DESC
)
SELECT top 1
    C.CustomerID,
    C.CompanyName,
    SUM(OD.UnitPrice * OD.Quantity * (1 - OD.Discount)) AS TotalSales
FROM Customers C
JOIN Orders O ON C.CustomerID = O.CustomerID
JOIN [Order Details] OD ON O.OrderID = OD.OrderID
JOIN Products P ON OD.ProductID = P.ProductID
WHERE P.SupplierID IN (
    SELECT SupplierID FROM TopSupplier
)
AND O.OrderID IN (
    SELECT O2.OrderID
    FROM Orders O2
    JOIN [Order Details] OD2 ON O2.OrderID = OD2.OrderID
    JOIN Products P2 ON OD2.ProductID = P2.ProductID
    WHERE P2.SupplierID = (SELECT TOP 1 SupplierID FROM TopSupplier)
)
GROUP BY C.CustomerID, C.CompanyName
ORDER BY TotalSales DESC


-- 26列出那些產品沒有人買過
select
*
from Products p 
left outer join [Order Details] od on p.ProductID = od.ProductID
where od.ProductID is null

-- 27列出沒有傳真 (Fax) 的客戶和它的消費總金額
with t1 as(
	select
		c.CompanyName,
		c.CustomerID,
		SUM(od.UnitPrice*od.Quantity*(1-od.Discount)) as totalmoney

	from Customers c
	join Orders o ON o.CustomerID = c.CustomerID
	join [Order Details] od ON od.OrderID = o.OrderID
	join Products p ON p.ProductID = od.ProductID

	group by c.CompanyName,c.CustomerID
	
)
select 
	c.CompanyName,
	c.CustomerID,
	c.Fax,
	t.totalmoney
from Customers c
join t1 t on t.CustomerID = c.CustomerID
where c.Fax is null and c.CustomerID in(
	select t.CustomerID
	from t1 t
)
-- 28列出每一個城市消費的產品種類數量
SELECT o.ShipCity, COUNT(DISTINCT p.ProductID) AS num_products
FROM Orders o
JOIN [Order Details] od ON o.OrderID = od.OrderID
JOIN Products p ON p.ProductID = od.ProductID
GROUP BY o.ShipCity
ORDER BY num_products DESC;



-- 29列出目前沒有庫存的產品在過去總共被訂購的數量
with t1 as(
	select
		od.ProductID,
		SUM(od.Quantity) as totalorder
	from [Order Details] od
	group by od.ProductID
),
t2 as (
	select
		p.ProductID,
		p.ProductName,
		p.UnitsInStock
	from Products p
)
select
	t2.UnitsInStock,
	t2.ProductName,
	t1.totalorder
from t1 
join t2 on t2.ProductID = t1.ProductID
where t2.UnitsInStock = 0
-- 30列出目前沒有庫存的產品在過去曾經被那些客戶訂購過
with t2 as (
	select
		p.ProductID,
		p.ProductName,
		p.UnitsInStock
	from Products p
)
select 
	t2.ProductName,
	c.CompanyName,
	t2.UnitsInStock,
	od.Quantity
from Customers c
join Orders o on o.CustomerID = c.CustomerID
join [Order Details] od on od.OrderID = o.OrderID
join Products p on p.ProductID = od.ProductID
join t2 on t2.ProductID = p.ProductID
where t2.UnitsInStock = 0;
-- 31列出每位員工的下屬的業績總金額
WITH DirectReports(EmployeeID, FirstName, LastName) AS (
  SELECT EmployeeID, FirstName, LastName
  FROM Employees
  WHERE ReportsTo IS NULL
  UNION ALL
  SELECT e.EmployeeID, e.FirstName, e.LastName
  FROM Employees e
  JOIN DirectReports d ON d.EmployeeID = e.ReportsTo
)

SELECT d.FirstName + ' ' + d.LastName AS EmployeeName, 
       SUM(od.UnitPrice * od.Quantity * (1 - od.Discount)) AS TotalSales
FROM DirectReports d
JOIN Employees e ON d.EmployeeID = e.EmployeeID
JOIN Orders o ON e.EmployeeID = o.EmployeeID
JOIN [Order Details] od ON o.OrderID = od.OrderID
GROUP BY d.EmployeeID, d.FirstName, d.LastName;
-- 32列出每家貨運公司運送最多的那一種產品類別與總數量
SELECT TOP 1 
	ShipperCompanyName = s.CompanyName,
	ProductCategory = c.CategoryName,
	TotalQuantity = SUM(od.Quantity)
FROM Shippers s
JOIN Orders o ON o.ShipVia = s.ShipperID
JOIN [Order Details] od ON od.OrderID = o.OrderID
JOIN Products p ON p.ProductID = od.ProductID
JOIN Categories c ON c.CategoryID = p.CategoryID
GROUP BY s.CompanyName, c.CategoryName
ORDER BY TotalQuantity DESC;


-- 33列出每一個客戶買最多的產品類別與金額
WITH customer_order_totals AS (
  SELECT 
    o.CustomerID, 
    od.ProductID, 
    SUM(od.Quantity * od.UnitPrice * (1 - od.Discount)) AS order_total
  FROM Orders o 
  JOIN [Order Details] od ON o.OrderID = od.OrderID
  GROUP BY o.CustomerID, od.ProductID
),
customer_top_product AS (
  SELECT 
    cot.CustomerID, 
    p.CategoryID, 
    MAX(cot.order_total) AS max_order_total
  FROM customer_order_totals cot 
  JOIN Products p ON cot.ProductID = p.ProductID
  GROUP BY cot.CustomerID, p.CategoryID
)
SELECT 
  c.CompanyName, 
  cat.CategoryName, 
  ctp.max_order_total
FROM customer_top_product ctp 
JOIN Customers c ON ctp.CustomerID = c.CustomerID 
JOIN Categories cat ON ctp.CategoryID = cat.CategoryID;

-- 34列出每一個客戶買最多的那一個產品與購買數量
with customer_order_total as(
	select
		c.CustomerID,
		c.CompanyName,
		SUM(od.UnitPrice*od.Quantity*(1-od.Discount)) as TotalAmout
	from Customers c
	JOIN Orders o on o.CustomerID = c.CustomerID
	join [Order Details] od on od.OrderID = o.OrderID
	group by c.CustomerID  ,c.CompanyName
),	

customer_buy_most as(
	select
		custot.CustomerID,
		p.ProductID,
		MAX(od.Quantity) as max_quan
	from customer_order_total custot
	join Orders o on o.CustomerID = custot.CustomerID
	join [Order Details] od on od.OrderID = o.OrderID
	join Products p  on p.ProductID = od.ProductID
	 GROUP BY custot.CustomerID, p.ProductID
)
select
	p.ProductName,
	c.CompanyName,
	cbm.max_quan
from customer_buy_most cbm
join Products p on p.ProductID = cbm.ProductID
join  Customers c on c.CustomerID = cbm.CustomerID
-- 34按照城市分類，找出每一個城市最近一筆訂單的送貨時間
SELECT o.ShipCity, MAX(o.ShippedDate) AS LastShippedDate
FROM Orders o
WHERE o.ShippedDate IS NOT NULL 
AND o.ShipCity IS NOT NULL
AND o.ShippedDate = (
    SELECT MAX(o2.ShippedDate) 
    FROM Orders o2 
    WHERE o2.ShipCity = o.ShipCity
)
GROUP BY o.ShipCity;


-- 35列出購買金額第五名與第十名的客戶，以及兩個客戶的金額差距
WITH ranked_customers AS (
  SELECT 
    c.CustomerID, 
    c.CompanyName, 
    SUM(od.UnitPrice * od.Quantity * (1 - od.Discount)) AS TotalAmount,
    RANK() OVER (ORDER BY SUM(od.UnitPrice * od.Quantity * (1 - od.Discount)) DESC) AS rank
  FROM Customers c
  JOIN Orders o ON o.CustomerID = c.CustomerID
  JOIN [Order Details] od ON od.OrderID = o.OrderID
  GROUP BY c.CustomerID, c.CompanyName
),
ranked_customers_5 AS (
  SELECT CustomerID, CompanyName, TotalAmount
  FROM ranked_customers
  WHERE rank = 5
),
ranked_customers_10 AS (
  SELECT CustomerID, CompanyName, TotalAmount
  FROM ranked_customers
  WHERE rank = 10
)
SELECT 
  rc5.CompanyName AS FifthCustomer,
  rc10.CompanyName AS TenthCustomer,
  rc5.TotalAmount - rc10.TotalAmount AS AmountDifference
FROM ranked_customers_5 rc5
JOIN ranked_customers_10 rc10 ON rc5.CustomerID != rc10.CustomerID;



