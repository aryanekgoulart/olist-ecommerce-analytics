import pandas as pd

# Arquivo original
input_file = "data/raw/olist_order_reviews_dataset.csv"

# Arquivo tratado
output_file = "data/processed/olist_order_reviews_clean.csv"

# Leitura do CSV
df = pd.read_csv(input_file)

# Manter somente as colunas necessárias para o projeto
df_clean = df[
    [
        "review_id",
        "order_id",
        "review_score",
        "review_creation_date",
        "review_answer_timestamp"
    ]
].copy()

# Converter datas
df_clean["review_creation_date"] = pd.to_datetime(
    df_clean["review_creation_date"]
)

df_clean["review_answer_timestamp"] = pd.to_datetime(
    df_clean["review_answer_timestamp"]
)

# Salvar novo CSV
df_clean.to_csv(
    output_file,
    index=False,
    encoding="utf-8"
)

# Validações
print("Arquivo criado com sucesso!")
print(f"Quantidade de registros: {len(df_clean)}")
print(f"Quantidade de colunas: {len(df_clean.columns)}")
print("\nColunas:")
print(df_clean.columns.tolist())

print("\nPrimeiras linhas:")
print(df_clean.head())