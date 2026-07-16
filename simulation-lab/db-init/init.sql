-- Script de Inicializacion y Poblacion de Base de Datos para el Laboratorio de Simulacion (PostgreSQL)
-- NOTA: Este script genera ~25,000 clientes y ~5,000 productos para que la respuesta JSON
-- de las queries supere los 10 MB del maxPayload del WebSocket, forzando el error de limite.

-- 1. Tabla de Configuracion de la Empresa
CREATE TABLE configuracion (
    NombreEmpresa VARCHAR(150),
    Direccion1 VARCHAR(250),
    Fiscal1 VARCHAR(50),
    Telefonos VARCHAR(50),
    EMail VARCHAR(100)
);

-- 2. Tabla de Monedas
CREATE TABLE monedas (
    Codigo VARCHAR(10) PRIMARY KEY,
    Descripcion VARCHAR(50),
    Simbol VARCHAR(5),
    ParaVenta NUMERIC(18, 4)
);

-- 3. Tabla de Bancos
CREATE TABLE fbancos (
    idbanco VARCHAR(10) PRIMARY KEY,
    Descripcion VARCHAR(100),
    id_moneda VARCHAR(10) REFERENCES monedas(Codigo)
);

-- 4. Tabla de Clientes
CREATE TABLE clientes (
    Codigo VARCHAR(20) PRIMARY KEY,
    Descripcion VARCHAR(150),
    Direccion1 VARCHAR(250),
    Telefonos VARCHAR(50),
    IdVendedor VARCHAR(20),
    TipoPrecio INT,
    Rif VARCHAR(50),
    PermiteCredito BOOLEAN,
    LimiteCredito NUMERIC(18, 2),
    DiasCredito INT,
    Contact VARCHAR(100),
    Email VARCHAR(100),
    Descto NUMERIC(5, 2),
    NumeroUV VARCHAR(20),
    FechaUV DATE,
    NumeroUP VARCHAR(20),
    FechaUP DATE
);

-- 5. Tabla de Cuentas por Cobrar
CREATE TABLE ctsxcobrar (
    AutoIncrField SERIAL PRIMARY KEY,
    IdCliente VARCHAR(20) REFERENCES clientes(Codigo),
    Id VARCHAR(20),
    IdVendedor VARCHAR(20),
    NroDocumt VARCHAR(20),
    Tipo VARCHAR(10),
    SaldoAct NUMERIC(18, 2),
    Factor NUMERIC(18, 4),
    FEmision DATE,
    FVenc DATE
);

-- 6. Tabla de Inventario / Productos
CREATE TABLE inventario (
    Codigo VARCHAR(20) PRIMARY KEY,
    Departamento VARCHAR(20),
    Descripcion1 VARCHAR(150),
    Precio_Maximo NUMERIC(18, 2),
    Precio_Minimo NUMERIC(18, 2),
    Precio_Mayor NUMERIC(18, 2),
    Precio_Detal NUMERIC(18, 2),
    Precio_Oferta NUMERIC(18, 2),
    Exento BOOLEAN,
    Impuesto NUMERIC(5, 2),
    Refere VARCHAR(50),
    Marca VARCHAR(50),
    Modelo VARCHAR(50),
    FechaUV DATE,
    IDMoneda VARCHAR(10) REFERENCES monedas(Codigo)
);

-- ======================================================================
-- POBLAR CON DATOS DE PRUEBA
-- ======================================================================

-- Insertar Datos en Configuracion
INSERT INTO configuracion (NombreEmpresa, Direccion1, Fiscal1, Telefonos, EMail)
VALUES ('Corporacion Tecnologica Industrial C.A.', 'Zona Industrial I, Galpon 12, Barquisimeto, Venezuela', 'J-12345678-9', '+58-251-5551234', 'info@corptech.com');

-- Insertar Monedas
INSERT INTO monedas (Codigo, Descripcion, Simbol, ParaVenta) VALUES
('USD', 'Dolar Estadounidense', '$', 1.0000),
('EUR', 'Euro', 'E', 1.0850),
('VES', 'Bolivar Soberano', 'Bs', 36.5000);

-- Insertar Bancos
INSERT INTO fbancos (idbanco, Descripcion, id_moneda) VALUES
('B-01', 'Banco Provincial', 'VES'),
('B-02', 'Banesco', 'VES'),
('B-03', 'Chase Bank', 'USD');

-- ======================================================================
-- GENERACION MASIVA: ~25,000 CLIENTES
-- Cada fila en JSON ocupa ~450-500 bytes.
-- 25,000 filas * ~500 bytes = ~12.5 MB, superando los 10 MB del maxPayload.
-- ======================================================================

-- Arrays de datos para generar nombres realistas
DO $$
DECLARE
    nombres TEXT[] := ARRAY[
        'Inversiones', 'Distribuciones', 'Comercializadora', 'Importadora', 'Exportadora',
        'Servicios', 'Suministros', 'Tecnologia', 'Corporacion', 'Grupo',
        'Soluciones', 'Proyectos', 'Consultores', 'Ferreteria', 'Farmacia',
        'Automotriz', 'Construcciones', 'Materiales', 'Alimentos', 'Telecomunicaciones'
    ];
    apellidos TEXT[] := ARRAY[
        'Martinez', 'Rodriguez', 'Gonzalez', 'Hernandez', 'Lopez',
        'Garcia', 'Perez', 'Sanchez', 'Ramirez', 'Torres',
        'Flores', 'Rivera', 'Gomez', 'Diaz', 'Reyes',
        'Morales', 'Jimenez', 'Ruiz', 'Alvarez', 'Romero'
    ];
    ciudades TEXT[] := ARRAY[
        'Caracas', 'Maracaibo', 'Valencia', 'Barquisimeto', 'Maracay',
        'Ciudad Guayana', 'Barcelona', 'Maturin', 'Cumana', 'Merida',
        'San Cristobal', 'Punto Fijo', 'Cabimas', 'Los Teques', 'Guarenas',
        'Puerto La Cruz', 'Coro', 'Guanare', 'Acarigua', 'Valera'
    ];
    calles TEXT[] := ARRAY[
        'Av. Bolivar', 'Calle Principal', 'Av. Libertador', 'Calle Comercio', 'Av. Universidad',
        'Calle Miranda', 'Av. Las Americas', 'Calle Sucre', 'Av. Fuerzas Armadas', 'Calle 5 de Julio',
        'Av. Paez', 'Calle Urdaneta', 'Av. Intercomunal', 'Calle Vargas', 'Av. Los Ilustres',
        'Calle Lara', 'Av. Principal', 'Calle Falcon', 'Av. Andres Bello', 'Calle Carabobo'
    ];
    vendedores TEXT[] := ARRAY['VEND-01','VEND-02','VEND-03','VEND-04','VEND-05','VEND-06','VEND-07','VEND-08','VEND-09','VEND-10'];
    tipos_precio INT[] := ARRAY[1, 2, 3];
    contacto_nombres TEXT[] := ARRAY[
        'Pedro', 'Maria', 'Carlos', 'Ana', 'Luis',
        'Jose', 'Carmen', 'Miguel', 'Rosa', 'Juan',
        'Elena', 'Ricardo', 'Lucia', 'Fernando', 'Patricia',
        'Andres', 'Isabel', 'Rafael', 'Teresa', 'Jorge'
    ];
    sufijos TEXT[] := ARRAY['S.A.', 'C.A.', 'S.R.L.', 'y Asociados', 'del Centro', 'del Este', 'del Norte', 'del Sur', 'Internacional', 'Venezuela'];
    i INT;
    cli_codigo TEXT;
    cli_nombre TEXT;
    cli_dir TEXT;
    cli_tel TEXT;
    cli_vend TEXT;
    cli_tipo INT;
    cli_rif TEXT;
    cli_credito BOOLEAN;
    cli_limite NUMERIC;
    cli_dias INT;
    cli_contacto TEXT;
    cli_email TEXT;
    cli_descuento NUMERIC;
    cli_fecha_uv DATE;
    cli_fecha_up DATE;
BEGIN
    FOR i IN 1..25000 LOOP
        cli_codigo := 'CLI-' || LPAD(i::TEXT, 6, '0');
        cli_nombre := nombres[1 + (i % array_length(nombres, 1))] || ' ' ||
                      apellidos[1 + ((i * 7) % array_length(apellidos, 1))] || ' ' ||
                      sufijos[1 + ((i * 3) % array_length(sufijos, 1))];
        cli_dir := calles[1 + ((i * 11) % array_length(calles, 1))] || ', Local ' || (i % 500 + 1)::TEXT || ', ' ||
                   ciudades[1 + ((i * 13) % array_length(ciudades, 1))];
        cli_tel := '+58-' || (200 + (i % 61))::TEXT || '-' || LPAD((1000000 + (i * 17) % 9000000)::TEXT, 7, '0');
        cli_vend := vendedores[1 + (i % array_length(vendedores, 1))];
        cli_tipo := tipos_precio[1 + (i % array_length(tipos_precio, 1))];
        cli_rif := CASE WHEN i % 3 = 0 THEN 'J-' WHEN i % 3 = 1 THEN 'V-' ELSE 'G-' END ||
                   LPAD((10000000 + i)::TEXT, 8, '0') || '-' || (i % 10)::TEXT;
        cli_credito := (i % 4 != 0);
        cli_limite := CASE WHEN cli_credito THEN (1000 + (i * 37) % 50000)::NUMERIC ELSE 0 END;
        cli_dias := CASE WHEN cli_credito THEN (ARRAY[15, 30, 45, 60, 90])[1 + (i % 5)] ELSE 0 END;
        cli_contacto := contacto_nombres[1 + (i % array_length(contacto_nombres, 1))] || ' ' ||
                        apellidos[1 + ((i * 11) % array_length(apellidos, 1))];
        cli_email := LOWER(
            contacto_nombres[1 + (i % array_length(contacto_nombres, 1))] || '.' ||
            apellidos[1 + ((i * 11) % array_length(apellidos, 1))] || i::TEXT || '@example.com'
        );
        cli_descuento := (i % 20)::NUMERIC;
        cli_fecha_uv := '2025-01-01'::DATE + (i % 545);
        cli_fecha_up := cli_fecha_uv + (i % 30);

        INSERT INTO clientes (Codigo, Descripcion, Direccion1, Telefonos, IdVendedor, TipoPrecio, Rif,
                              PermiteCredito, LimiteCredito, DiasCredito, Contact, Email, Descto,
                              NumeroUV, FechaUV, NumeroUP, FechaUP)
        VALUES (
            cli_codigo,
            cli_nombre,
            cli_dir,
            cli_tel,
            cli_vend,
            cli_tipo,
            cli_rif,
            cli_credito,
            cli_limite,
            cli_dias,
            cli_contacto,
            cli_email,
            cli_descuento,
            'FAC-' || LPAD(i::TEXT, 6, '0'),
            cli_fecha_uv,
            'REC-' || LPAD(i::TEXT, 6, '0'),
            cli_fecha_up
        );
    END LOOP;
    RAISE NOTICE 'Generados 25,000 clientes exitosamente.';
END $$;

-- ======================================================================
-- GENERACION MASIVA: ~5,000 PRODUCTOS
-- Para probar tambien con get_productos
-- ======================================================================

DO $$
DECLARE
    departamentos TEXT[] := ARRAY[
        'ELECTRONICA', 'COMPUTACION', 'SERVICIOS', 'FERRETERIA', 'HOGAR',
        'OFICINA', 'REPUESTOS', 'ILUMINACION', 'SEGURIDAD', 'REDES'
    ];
    marcas TEXT[] := ARRAY[
        'TP-Link', 'Kingston', 'Samsung', 'LG', 'Epson',
        'HP', 'Dell', 'Lenovo', 'Cisco', 'Ubiquiti',
        'Hikvision', 'Dahua', 'WD', 'Seagate', 'Corsair',
        'Logitech', 'Microsoft', 'Intel', 'AMD', 'ASUS'
    ];
    modelos TEXT[] := ARRAY[
        'Pro', 'Elite', 'Max', 'Ultra', 'Plus',
        'Standard', 'Basic', 'Premium', 'Advanced', 'Lite',
        'X1', 'X2', 'X3', 'S100', 'S200',
        'T500', 'T600', 'M300', 'M400', 'V100'
    ];
    prefijos TEXT[] := ARRAY[
        'Router', 'Switch', 'Disco Duro', 'Monitor', 'Impresora',
        'Teclado', 'Mouse', 'Cable UTP', 'Camara IP', 'Access Point',
        'Fuente de Poder', 'Memoria RAM', 'Procesador', 'Tarjeta de Video', 'Gabinete',
        'Pantalla LED', 'Proyector', 'Scanner', 'UPS', 'Regulador de Voltaje'
    ];
    i INT;
    prod_codigo TEXT;
    prod_depto TEXT;
    prod_desc TEXT;
    prod_pmax NUMERIC;
    prod_pmin NUMERIC;
    prod_pmayor NUMERIC;
    prod_pdetal NUMERIC;
    prod_poferta NUMERIC;
    prod_exento BOOLEAN;
    prod_iva NUMERIC;
    prod_ref TEXT;
    prod_marca TEXT;
    prod_modelo TEXT;
    prod_fecha DATE;
    monedas_arr TEXT[] := ARRAY['USD', 'EUR', 'VES'];
BEGIN
    FOR i IN 1..5000 LOOP
        prod_codigo := 'PROD-' || LPAD(i::TEXT, 5, '0');
        prod_depto := departamentos[1 + (i % array_length(departamentos, 1))];
        prod_desc := prefijos[1 + (i % array_length(prefijos, 1))] || ' ' ||
                     marcas[1 + ((i * 3) % array_length(marcas, 1))] || ' ' ||
                     modelos[1 + ((i * 7) % array_length(modelos, 1))] || ' - Lote ' || i::TEXT;
        prod_pmax := 10.00 + (i * 13 % 990)::NUMERIC;
        prod_pmin := prod_pmax * 0.75;
        prod_pmayor := prod_pmax * 0.70;
        prod_pdetal := prod_pmax * 0.90;
        prod_poferta := prod_pmax * 0.80;
        prod_exento := (i % 10 = 0);
        prod_iva := CASE WHEN prod_exento THEN 0.00 ELSE 16.00 END;
        prod_ref := 'REF-' || prod_depto || '-' || i::TEXT;
        prod_marca := marcas[1 + ((i * 3) % array_length(marcas, 1))];
        prod_modelo := modelos[1 + ((i * 7) % array_length(modelos, 1))] || '-' || (i % 100)::TEXT;
        prod_fecha := '2025-01-01'::DATE + (i % 545);

        INSERT INTO inventario (Codigo, Departamento, Descripcion1, Precio_Maximo, Precio_Minimo,
                                Precio_Mayor, Precio_Detal, Precio_Oferta, Exento, Impuesto,
                                Refere, Marca, Modelo, FechaUV, IDMoneda)
        VALUES (
            prod_codigo,
            prod_depto,
            prod_desc,
            prod_pmax,
            prod_pmin,
            prod_pmayor,
            prod_pdetal,
            prod_poferta,
            prod_exento,
            prod_iva,
            prod_ref,
            prod_marca,
            prod_modelo,
            prod_fecha,
            monedas_arr[1 + (i % array_length(monedas_arr, 1))]
        );
    END LOOP;
    RAISE NOTICE 'Generados 5,000 productos exitosamente.';
END $$;

-- ======================================================================
-- GENERACION MASIVA: Cuentas por Cobrar para los primeros 5,000 clientes
-- Cada cliente con 1-3 cuentas pendientes
-- ======================================================================

DO $$
DECLARE
    vendedores TEXT[] := ARRAY['VEND-01','VEND-02','VEND-03','VEND-04','VEND-05','VEND-06','VEND-07','VEND-08','VEND-09','VEND-10'];
    tipos_doc TEXT[] := ARRAY['FAC', 'ND', 'NC'];
    i INT;
    j INT;
    num_cuentas INT;
    cli_codigo TEXT;
BEGIN
    FOR i IN 1..5000 LOOP
        cli_codigo := 'CLI-' || LPAD(i::TEXT, 6, '0');
        num_cuentas := 1 + (i % 3);
        FOR j IN 1..num_cuentas LOOP
            INSERT INTO ctsxcobrar (IdCliente, Id, IdVendedor, NroDocumt, Tipo, SaldoAct, Factor, FEmision, FVenc)
            VALUES (
                cli_codigo,
                'CXC-' || LPAD(((i - 1) * 3 + j)::TEXT, 7, '0'),
                vendedores[1 + (i % array_length(vendedores, 1))],
                tipos_doc[1 + (j % array_length(tipos_doc, 1))] || '-2026-' || LPAD(((i - 1) * 3 + j)::TEXT, 6, '0'),
                tipos_doc[1 + (j % array_length(tipos_doc, 1))],
                (100 + (i * 17 + j * 31) % 25000)::NUMERIC,
                1.0000,
                '2025-06-01'::DATE + (i % 365),
                '2025-06-01'::DATE + (i % 365) + 30 + (j * 15)
            );
        END LOOP;
    END LOOP;
    RAISE NOTICE 'Generadas cuentas por cobrar exitosamente.';
END $$;
