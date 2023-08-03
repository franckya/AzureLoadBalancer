# Define variables
group=Prod
location=eastus
vnet_name=vm-vnet
subnet_name=subnet
as_name=vm-as
username=frakengne
password='ChangeMe123#$'

# Create resource group
az group create -g $group -l $location

# Create virtual network and subnet
az network vnet create \
  -n $vnet_name \
  -g $group \
  -l $location \
  --address-prefixes '192.168.0.0/16' \
  --subnet-name $subnet_name \
  --subnet-prefixes '192.168.1.0/24'

# Create availability set
az vm availability-set create \
  -n $as_name \
  -l $location \
  -g $group

# Create virtual machines
for NUM in 1 2 3
do
  az vm create \
    -n vm-eu-0$NUM \
    -g $group \
    -l $location \
    --size Standard_B1s \
    --image Win2019Datacenter \
    --admin-username $username \
    --admin-password $password \
    --vnet-name $vnet_name \
    --subnet $subnet_name \
    --public-ip-address "" \
    --availability-set $as_name \
	  --nsg vm-nsg
done

# Open port 80 for the virtual machines
for NUM in 1 2 3
do
  az vm open-port -g $group --name vm-eu-0$NUM --port 80
done

# Install IIS and configure default page on the virtual machines
for NUM in 1 2 3
do
  az vm extension set \
    --name CustomScriptExtension \
    --vm-name vm-eu-0$NUM \
    -g $group \
    --publisher Microsoft.Compute \
    --version 1.8 \
    --settings '{"commandToExecute":"powershell Add-WindowsFeature Web-Server; powershell Add-Content -Path \"C:\\inetpub\\wwwroot\\Default.htm\" -Value $($env:computername)"}'
done

