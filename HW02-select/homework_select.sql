/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.
Занятие "02 - Оператор SELECT и простые фильтры, JOIN".

Задания выполняются с использованием базы данных WideWorldImporters.

-- ---------------------------------------------------------------------------
-- Задание - написать выборки для получения указанных ниже данных.
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. Все товары, в названии которых есть "urgent" или название начинается с "Animal".
Вывести: ИД товара (StockItemID), наименование товара (StockItemName).
Таблицы: Warehouse.StockItems.
*/

SELECT StockItemID, StockItemName
FROM Warehouse.StockItems
WHERE StockItemName like '%urgent%' or StockItemName like 'Animal%'

/*
2. Поставщиков (Suppliers), у которых не было сделано ни одного заказа (PurchaseOrders).
Сделать через JOIN, с подзапросом задание принято не будет.
Вывести: ИД поставщика (SupplierID), наименование поставщика (SupplierName).
Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders.
По каким колонкам делать JOIN подумайте самостоятельно.
*/

SELECT 
a.SupplierID,
a.SupplierName
FROM Purchasing.Suppliers a 
left join Purchasing.PurchaseOrders d on a.SupplierID=d.SupplierID
where d.PurchaseOrderID is null

/*
3. Заказы (Orders) с ценой товара (UnitPrice) более 100$ 
либо количеством единиц (Quantity) товара более 20 штук
и присутствующей датой комплектации всего заказа (PickingCompletedWhen).
Вывести:
* OrderID
* дату заказа (OrderDate) в формате ДД.ММ.ГГГГ
* название месяца, в котором был сделан заказ
* номер квартала, в котором был сделан заказ
* треть года, к которой относится дата заказа (каждая треть по 4 месяца)
* имя заказчика (Customer)
Добавьте вариант этого запроса с постраничной выборкой,
пропустив первую 1000 и отобразив следующие 100 записей.

Сортировка должна быть по номеру квартала, трети года, дате заказа (везде по возрастанию).

Таблицы: Sales.Orders, Sales.OrderLines, Sales.Customers.
*/

SELECT
a.OrderID,
convert(varchar(10), a.OrderDate, 104) as OrderDate, 
datename(month, a.OrderDate) as Месяц,
datepart(quarter, a.OrderDate) as Квартал,
CASE 
WHEN month(a.OrderDate) BETWEEN 1 AND 4 THEN 1
WHEN month(a.OrderDate) BETWEEN 5 AND 8 THEN 2
ELSE 3 END AS ТретьГода,
d.CustomerName as Custome   
FROM Sales.Orders a
inner join Sales.OrderLines s ON a.OrderID = s.OrderID
inner join Sales.Customers d ON a.CustomerID = d.CustomerID
WHERE (s.UnitPrice > 100.00 OR s.Quantity > 20) AND a.PickingCompletedWhen IS NOT NULL
GROUP BY a.OrderID, a.OrderDate, d.CustomerName
ORDER BY 
Квартал ASC,
ТретьГода ASC,
a.OrderDate ASC
OFFSET 1000 ROWS
FETCH NEXT 100 ROWS ONLY

/*
4. Заказы поставщикам (Purchasing.Suppliers),
которые должны быть исполнены (ExpectedDeliveryDate) в январе 2013 года
с доставкой "Air Freight" или "Refrigerated Air Freight" (DeliveryMethodName)
и которые исполнены (IsOrderFinalized).
Вывести:
* способ доставки (DeliveryMethodName)
* дата доставки (ExpectedDeliveryDate)
* имя поставщика
* имя контактного лица принимавшего заказ (ContactPerson)

Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders, Application.DeliveryMethods, Application.People.
*/

SELECT 
    s.DeliveryMethodName,
    d.ExpectedDeliveryDate,
    a.SupplierName,
    t.FullName as ContactPerson
FROM Purchasing.PurchaseOrders d
inner join Purchasing.Suppliers a ON d.SupplierID = a.SupplierID
inner join Application.DeliveryMethods s ON d.DeliveryMethodID = s.DeliveryMethodID
inner join Application.People t ON d.ContactPersonID = t.PersonID
WHERE d.ExpectedDeliveryDate >= '20130101' AND d.ExpectedDeliveryDate < '20130201'
AND (s.DeliveryMethodName like 'Air Freight'or s.DeliveryMethodName like 'Refrigerated Air Freight')
AND d.IsOrderFinalized = 1

/*
5. Десять последних продаж (по дате продажи) с именем клиента и именем сотрудника,
который оформил заказ (SalespersonPerson).
Сделать без подзапросов.
*/

SELECT TOP (10) WITH TIES
    a.OrderID,
    a.OrderDate,
    d.CustomerName,
    t.FullName AS SalespersonPerson
FROM Sales.Orders a
inner join Sales.Customers d ON a.CustomerID = d.CustomerID
inner join Application.People t ON a.SalespersonPersonID = t.PersonID
ORDER BY a.OrderDate DESC

/*
6. Все ид и имена клиентов и их контактные телефоны,
которые покупали товар "Chocolate frogs 250g".
Имя товара смотреть в таблице Warehouse.StockItems.
*/
SELECT 
    a.CustomerID,
    a.CustomerName,
    a.PhoneNumber
FROM Sales.Customers a
inner join Sales.Orders d ON a.CustomerID = d.CustomerID
inner join Sales.OrderLines t ON d.OrderID = t.OrderID
inner join Warehouse.StockItems s ON t.StockItemID = s.StockItemID
WHERE s.StockItemName = 'Chocolate frogs 250g'
GROUP BY a.CustomerID, a.CustomerName, a.PhoneNumber
