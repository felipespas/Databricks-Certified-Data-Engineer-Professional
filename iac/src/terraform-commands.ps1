az login --tenant fdc05157-1e94-498e-8203-620b05e4e00d

cd C:\_Github\Databricks-Certified-Data-Engineer-Professional\iac\src

# Inicializa os providers; execute este script a partir do diretorio iac/src.
terraform init

# Formata os arquivos Terraform.
terraform fmt -recursive

# Valida a configuracao Terraform.
terraform validate

# Executa os testes locais com o provider simulado.
terraform test

# Gera e salva o plano de provisionamento.
terraform plan "-out=dev.tfplan"

# Provisiona os recursos do plano salvo e pode gerar custos no Azure.
terraform apply dev.tfplan

# Exibe os outputs dos recursos provisionados.
terraform output
