-- EVALUACION MODULO 1 SPRINT 2 SQL --
USE northwind;

/*1. Selecciona todos los campos de los productos, que pertenezcan a los proveedores con códigos: 
1, 3, 7, 8 y 9, que tengan stock en el almacén, y al mismo tiempo que sus precios unitarios estén 
entre 50 y 100. Por último, ordena los resultados por código de proveedor de forma ascendente.*/

-- Todos los campos (*) de products
-- de los proveedores (suplier_id) de supplier 1,3,7,8 y 9
-- precio entre 50 y 100
-- ordenado de manera ascendente

SELECT *
FROM products
NATURAL JOIN suppliers
WHERE supplier_id IN (1, 3, 7, 8, 9) 
	AND unit_price BETWEEN 50 AND 100 
    AND units_in_stock <> 0
ORDER BY supplier_id;


/*2. Devuelve el nombre y apellidos y el id de los empleados con códigos entre el 3 y el 6, además 
que hayan vendido a clientes que tengan códigos que comiencen con las letras de la A hasta la G. 
Por último, en esta búsqueda queremos filtrar solo por aquellos envíos que la fecha de pedido este 
comprendida entre el 22 y el 31 de Diciembre de cualquier año.*/

-- Necesitamos unir las tablas employees y orders para lo que empleamos un INNER JOIN, uniéndolas por el employee_id
-- A continuación vamos poniendole las condiciones solicitadas en el WHERE.

SELECT e.employee_id, e.first_name, e.last_name, o.order_date, o.customer_id
FROM employees AS e
INNER JOIN orders AS o ON e.employee_id = o.employee_id
WHERE e.employee_id BETWEEN 3 AND 6
	AND (DAY(o.order_date) BETWEEN 22 AND 31) AND MONTH(o.order_date) = 12
    AND o.customer_id REGEXP '^[A-G].*';

		
/*3. Calcula el precio de venta de cada pedido una vez aplicado el descuento. Muestra el id del la orden, 
el id del producto, el nombre del producto, el precio unitario, la cantidad, el descuento y el precio de venta 
después de haber aplicado el descuento.*/

-- Necesitamos datos de las tablas order_details y products, por lo que usamos un INNER JOIN
-- Ademas de los datos ya existentes en la tabla, nos piden que creemos un nuevo dato en el que se recoga el precio total de venta:
	-- Para ello hacemos el cálculo multiplicando el precio-unidad por la cantidad y le quitamos el descuento (como un porcentaje, se resta a 1(que seria el 100%) y se multiplica por nuestra cantidad*precio)

SELECT od.order_id, od.product_id, p.product_name, od.unit_price, od.quantity, 
od.discount, ROUND((od.unit_price * od.quantity) * (1 - od.discount), 2) AS precio_de_venta
FROM order_details AS od
INNER JOIN products AS p ON od.product_id = p.product_id;


/*4. Usando una subconsulta, muestra los productos cuyos precios estén por encima del precio medio total de los
 productos de la BBDD.*/
 
 -- Lo primero que hacemos es calcular la media total de precios: '28.87'
 -- Ese cálculo lo utilizaremos como una subconsulta sobre la que filtraremos la consulta principal, en este caso el precio de unidad

SELECT product_name, unit_price
FROM products
WHERE unit_price > (SELECT ROUND(AVG(unit_price), 2)
                    FROM products);


/*5. ¿Qué productos ha vendido cada empleado y cuál es la cantidad vendida de cada uno de ellos?*/

-- vamos a necesitar 4 tablas: employees, orders, order_details y products. Los uniremos con INNER JOIN
-- queremos saber cual es la cantidad total vendida de cada empleado para cada producto, para ello utilizamos la suma de cantidades como funcion agregada, agrupando por empleado y producto (ya que son únicas)

SELECT e.employee_id, e.first_name, e.last_name, od.order_id, od.product_id, p.product_name, SUM(od.quantity) AS cantidad_vendida
FROM employees AS e
	INNER JOIN orders AS o 
	ON e.employee_id = o.employee_id
	INNER JOIN order_details AS od 
	ON o.order_id = od.order_id
	INNER JOIN products AS p
	ON p.product_id = od.product_id
GROUP BY e.employee_id, od.product_id;


/*6. Basándonos en la query anterior, ¿qué empleado es el que vende más productos? Soluciona este ejercicio con una subquery*/

-- primero calculamos quien vende más en total suando orders y order_details
SELECT order_id, SUM(quantity) AS venta_total
FROM order_details
GROUP BY order_id
HAVING venta_total = MAX(venta_total);

-- ahora vemos como a qué empleado corresponde cada orden uniendo las tablas employees y orders:
SELECT e.first_name, e.last_name, o.order_id
FROM orders AS o
INNER JOIN employees AS e
ON o.employee_id = e.employee_id;

-- resuelto sin subquery
SELECT e.employee_id, e.first_name, e.last_name, o.order_id, SUM(od.quantity) AS cantidad_vendida
FROM employees AS e
INNER JOIN orders AS o
ON o.employee_id = e.employee_id
INNER JOIN order_details AS od
ON o.order_id = od.order_id
GROUP BY e.employee_id, e.first_name, e.last_name, o.order_id
ORDER BY SUM(od.quantity) DESC
LIMIT 1;

-- Intentamos llegar a la subquery apoyandonos en la resolucion del ejercicio siguiente, pero sin tabla
-- extra CTE no encontramos la solucion
SELECT e.employee_id, e.first_name, e.last_name, SUM(od.quantity) AS cantidad_vendida
FROM employees AS e
	INNER JOIN orders AS o 
	ON e.employee_id = o.employee_id
	INNER JOIN order_details AS od 
	ON o.order_id = od.order_id
GROUP BY e.employee_id
HAVING cantidad_vendida = (SELECT MAX(cantidad_vendida) FROM ventas_totales);


/*BONUS ¿Podríais solucionar este mismo ejercicio con una CTE?*/
-- creamos una nueva tabla temporal llamada ventas totales con la que calculamos las ventas totales por order_id
-- depués seleccionamos los datos que queremos recoger uniendo las tablas employees, order_details y mi tabla temporal ventas_totales
-- finalmente, aprovechamos la nueva tabla pata firltrar los datos, elijiendo unicamente el empleado cuya venta total sea igual al maximo de ventas totales

WITH ventas_totales AS (SELECT order_id, SUM(quantity) AS venta_total
						FROM order_details
						GROUP BY order_id)
SELECT e.employee_id, e.first_name, e.last_name, s.venta_total
FROM employees AS e
	INNER JOIN orders AS o
	ON e.employee_id = o.employee_id
	INNER JOIN order_details AS od
	ON od.order_id = o.order_id
	INNER JOIN ventas_totales AS s
	ON s.order_id = o.order_id
GROUP BY e.employee_id, e.first_name, e.last_name, s.venta_total
HAVING s.venta_total = (SELECT MAX(venta_total) FROM ventas_totales);



