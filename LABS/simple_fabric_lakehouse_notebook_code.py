# ============================================================
# SIMPLE MICROSOFT FABRIC LAKEHOUSE LAB
# Goal: Create sample data, load Bronze table, transform Silver table,
#       create Gold summary table, and run simple checks.
# ============================================================

from pyspark.sql import functions as F
import os

# STEP 1: Define paths and table names
raw_folder = "/lakehouse/default/Files/simple_lakehouse_lab"
raw_file = f"{raw_folder}/sales_sample.csv"

bronze_table = "bronze_sales_sample"
silver_table = "silver_sales_clean"
gold_table = "gold_sales_by_category"

# STEP 2: Create sample CSV file in Lakehouse Files
os.makedirs(raw_folder, exist_ok=True)

sample_csv = """OrderID,OrderDate,CustomerName,ProductName,Category,Quantity,UnitPrice
1001,2024-06-01,James Wilson,Wireless Headphones,Electronics,2,89.99
1002,2024-06-02,Sophia Martinez,Smart Watch,Electronics,1,249.99
1003,2024-06-03,Ethan Brown,Running Jacket,Clothing,2,79.99
1004,2024-06-04,Olivia Davis,Yoga Mat,Sports,3,29.99
"""

with open(raw_file, "w", encoding="utf-8") as f:
    f.write(sample_csv)

print("Sample file created:", raw_file)

# STEP 3: Read the CSV file
raw_df = (
    spark.read
    .option("header", True)
    .option("inferSchema", True)
    .csv(raw_file)
)

display(raw_df)

# STEP 4: Save raw data as Bronze Delta table
raw_df.write.format("delta").mode("overwrite").option("overwriteSchema", "true").saveAsTable(bronze_table)
print("Bronze table created:", bronze_table)

# STEP 5: Transform Bronze to Silver
silver_df = (
    spark.table(bronze_table)
    .withColumn("OrderDate", F.to_date("OrderDate"))
    .withColumn("Quantity", F.col("Quantity").cast("int"))
    .withColumn("UnitPrice", F.col("UnitPrice").cast("decimal(10,2)"))
    .withColumn("SalesAmount", F.round(F.col("Quantity") * F.col("UnitPrice"), 2))
)

silver_df.write.format("delta").mode("overwrite").option("overwriteSchema", "true").saveAsTable(silver_table)
print("Silver table created:", silver_table)
display(spark.table(silver_table))

# STEP 6: Create Gold summary table
gold_df = (
    spark.table(silver_table)
    .groupBy("Category")
    .agg(
        F.countDistinct("OrderID").alias("TotalOrders"),
        F.sum("Quantity").alias("TotalUnits"),
        F.round(F.sum("SalesAmount"), 2).alias("TotalSales")
    )
)

gold_df.write.format("delta").mode("overwrite").option("overwriteSchema", "true").saveAsTable(gold_table)
print("Gold table created:", gold_table)
display(spark.table(gold_table).orderBy(F.desc("TotalSales")))

# STEP 7: Simple audit checks
print("Bronze rows:", spark.table(bronze_table).count())
print("Silver rows:", spark.table(silver_table).count())
print("Gold rows:", spark.table(gold_table).count())
