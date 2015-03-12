Bibliometría para bibliotecarios utilizando el entorno R.
========================================================
Palabras claves: métodos bibliométricos, bases de datos relacionales, SQL, R, Web of Science, indicadores bibliométricos. 

Keywords: bibliometric methods, relacional data base, SQL, R, Web of Science, bibliometric indicators.

En este documento se presentan los principales hitos de la metodlogía que se describe en el trabajo sometido a revisión ...

###*1. Obtención del script con las Funciones*

Iniciaremos ***R*** o el entorno de trabajo integrado ***RStudio*** antes de proceder a la carga de las funciones que aquí se presentan y que están disponibles en el espacio web creado en: <https://github.com/06122010/r_isi>. 

Pinchando con el botón derecho sobre el fichero ***funciones.r***, se podrá guardar éste en la computadora del usuario. 

Desde la consola de ***R***, ejecute la siguiente instrucción:

```{r,eval=F}
> source(file="/.../.../funciones.r")
```
Con el comando `source` y el parámetro `file` (no olvide detallar la ruta de acceso al fichero descargado) se cargarán las funciones en el entorno ***R*** y estarán listas para su uso.

###*2. Carga de datos: El Dataframe principal WoS*

La función `isi_cargar` crea un *dataframe* que hemos llamado `WoS` en el que se cargan automáticamente todos los archivos que se encuentran en el directorio `“…/txt/”` (no olvide ni las *comillas* ni el *slash* final). 

El usuario indicará la ruta donde tenga almacenado los .txt de su descarga. Las funciones y demás desarrollos que se presentan aquí están ajustadas para tratar datos exportados de la *Web of Science* en formato separado por tabuladores. El usuario puede nombrar el dataframe como desee.

```{r,eval=FALSE}
> WoS <- isi_cargar("/.../txt/")
```

Si el usuario opta por trabajar directamente con el *dataframe* `WoS` en el propio entorno ***R***, podrá comenzar a obtener indicadores de los denominados unidimensionales, tales como frecuencias de datos referidos a la fecha (`PY`), tipología documental (`DT`), entre otros. 

Por ejemplo, una sencilla tabla de distribución de frecuencias de la variable fecha/año en el *dataframe* principal (`WoS$PY`), podría obtenerse así:

```{r,eval=F}
> q=as.data.frame(table(WoS$PY)) # Se genera una tabla (table) de frecuencias por año y se almacena en la variable "q" 
> q=cbind(q,F.Acum=cumsum(q$Freq)) # Se añade (cbind) a la tabla anterior una tercera columna con la frecuencia acumulada (cumsum)
> knitr::kable(q) # Se presenta la tabla generada
```
Con el simbolo `$` en la expresión `WoS$PY` se extrae como variable la columna con la fecha (`PY`) del *dataframe* `WoS`.


###*3. Exportación de datos a una BD relacional: Exportar el dataframe principal a SQLite*

Para exportar los datos a un sistema de bases de datos relacionales se emplea la función `isi_exportar_sqlite`. Como su nombre indica, exporta el *dataframe* que le indiquemos a una base de datos `SQLite`. Esta función trabaja con **dos parámetros**, el primero hace referencia al nombre del dataframe que queremos exportar (`WoS`) y el segundo a la tabla dónde queremos almacenar el contenido (`"Wos"`). 

Se creará una base de datos relacional, a la que hemos llamado **`pgwos.db`**, que se generará en el directorio raíz de la computadora.

Así pues, para exportar el *dataframe* `WoS` a la tabla principal de la base de datos ejecutamos la siguiente instrucción:

```{r,eval=FALSE}
> isi_exportar_sqlite(WoS,"WoS")
```
La tabla creada, con toda la información descargada se denominará `isi_t_pg`.

El usuario puede optar por gestionar la base `pgwos.db` con un cliente de `Sqlite` (recomendamos utilizar el más simple y  fácil de instalar como lo es el plugin de `Sqlite` para `Firefox`). Como alternativa, puede utilizar el propio entorno de ***R*** para interrogar a la base de datos, como se hace en las funciones de este trabajo, para lo cual es necesario cargar los paquetes `DBI`y `RSQLite`.


###*4. Separar datos y Exportar tablas a SQLite: Tablas de autores, instituciones y temáticas.*

En la información bibliográfica es habitual trabajar con campos de *ocurrencia múltiple* como el campo que hace referencia a los autores de un trabajo o al de su clasificación temática. Se ha programado una función `isi_separar` que permite procesar dichos datos separándolos en otros subconjuntos de datos. Este es el caso de los listados de autores, de direcciones, y categorías temáticas, entre otras. A continuación describimos el procedimiento para tales fines.

```{r, eval=FALSE}
#Creamos los diferentes Dataframes 
> autores <- isi_separar(WoS,"AU")
> direcciones <- isi_separar(WoS,"C1")
> temas <- isi_separar(WoS,"WC")
> categorias <- isi_separar(WoS,"SC")
> referencias <- isi_separar(WoS,"CR")
```

Una vez creados los subconjuntos de datos referentes a los autores, las direcciones, los temas, las categorías y las referencias bibliográficas, será necesario emplear de nuevo la función que hemos denominado `isi_separar`. En esta función se pueden enmplear los argumentos que describimos a continuación: `C1` para crear dataframe con las direcciones; `AU` para los autores; `WC` y/o `SC` para las categorías temáticas y `CR` para las referencias bibliográficas. 

A continuación crearemos cada uno de esos *dataframes* y luego los almacenamos en sus correspondientes tablas en la BD.

```{r, eval=FALSE} 
isi_exportar_sqlite(autores,"AU")
isi_exportar_sqlite(direcciones,"C1")
isi_exportar_sqlite(temas,"WC")
isi_exportar_sqlite(categorias,"SC")
isi_exportar_sqlite(referencias,"CR")
```

Como puede verse, la función `isi_exportar_sqlite`se ha programado también para exportar a la base de datos ya creada (***`pgwos.db`***) *tablas* con los siguientes datos: los autores `AU`en la tabla `isi_t_au`; las direcciones `C1` en la tabla `isi_t_c1`; los temas `WC` en la tabla `isi_t_wc`; las categorías `SC` en la tabla `isi_y_sc`y finalmente las referencias bibliográficas `CR` en la tabla `isi_t_cr`. 

###*5. Almacenar datos en fuentes externas*

A continuación, se explica brevemente cómo almacenar los datos en otras fuentes externas, para su posterior tratamiento con hojas de cálculo o con otros programas estadísticos.

```{r, eval=FALSE}
> write.table(WoS, "wos.txt", sep="\t") #La instrucción anterior salva los datos en un archivo .txt separado por tabulaciones
> write.csv(WoS, file = "wos.csv") # Una alternativa a la instrucción anterior
```

Si queremos salvar los datos en una hoja de Excel es necesario instalar y cargar la librería `xlsx`.


```{r,eval=FALSE}
> library(xlsx)
> write.xlsx(WoS, "wos.xlsx")
```

Adicionalmente podemos instalar y usar la librería `foreign` que permite importar y exportar datos a SPSS, SAS o Stata.

```{r, eval=FALSE}
> library(foreign)
> write.foreign(WoS, "wos.txt", "wos.sps",   package="SPSS") 
```

###*6. Obtención de algunos indicadores sencillos*














......






.....





......

