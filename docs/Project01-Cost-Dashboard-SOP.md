# Azure Essentials Project 01 - Azure Cost Visibility Dashboard (SOP)

> **DRAFT NOTE:** This draft was written from the lab guide before the build. Rows marked (expected) in Troubleshooting, and every `[Loom link]` or screenshot placeholder, get replaced with what really happens when you run it. Delete this box when the build is done.

**Time:** 3 to 4 hours  |  **Difficulty:** Beginner  |  **Cost:** close to zero for a short lab (budgets and action groups are free; Log Analytics and Logic Apps bill per use)

## What You Are Building

Small businesses move to the cloud and then get bills full of lines like "Microsoft.Compute/virtualMachines - $340" that nobody can read. This project builds a system that watches the spending, warns the owner before the bill gets out of hand, and shows the numbers on a dashboard.

**Interview line:** "I built a system that gives business owners real-time visibility into their Azure spend and alerts them before the bill becomes a problem." Lead with that. The tools are supporting details.

**WHAT THIS MEANS:** Think of your Azure subscription as the household bank account.
- The **budget** is an envelope with $200 of cash for the month.
- The **alerts** are your phone buzzing when the envelope is 25% empty ($50), half empty ($100), and fully empty ($200).
- The **resource group** is the box that holds every receipt and tool for this one project.
- **Terraform** is a written shopping list, so you can rebuild the exact same setup any time.

**NOTE:** The original lab guide also mentions a weekly comparison report. None of its steps build one, so this SOP does not claim it. If you add one later, add it to the "What You Built" table at the end.

## Before You Open VS Code

You need these ready before Phase 1. Each check should print a version number, not an error.

**Why:** Every phase uses these tools. Finding out one is missing halfway through costs you time.

**Prerequisites:**
- An Azure subscription where you are Owner or Contributor (creating budgets also needs Cost Management rights, see Troubleshooting)
- Terraform, Azure CLI, Git, and VS Code installed
- An email address that can receive the alerts

**PATH:** Use VS Code's built-in terminal (Terminal, then New Terminal, or press Ctrl+`). If you just installed a tool, close VS Code completely and reopen it. A new terminal tab is not enough for Windows to see the new tool.

```powershell
terraform --version
```

```powershell
az --version
```

```powershell
git --version
```

## Step 0 - Save Your Variables First

**What:** Put every name you will reuse into one file.
**Why:** Typing the same long names by hand is how typos happen. Load them once per terminal and every command can use `$RG`, `$AG`, and so on.

**VS Code:** In the Explorer sidebar on the left, open your project folder `project-1-cost-dashboard`. If you cloned the repo, `set-vars.ps1` is already there. If not, right-click an empty space, choose New File, name it `set-vars.ps1`, and paste in the file from the repo.

**PATH:** VS Code terminal, inside the project folder. Run it with a dot and a space in front so the values stay in your terminal session.

```powershell
. .\set-vars.ps1
```

**Verify:** You should see a green "Variables loaded" list with your names. If the `$RG` line is blank, the dot at the start was missed.

**SECURITY:** This file holds names only. Never put a password, key, or your email address in it, because it goes to GitHub.

## Phase 1 - Sign In to Azure

**What:** Log the Azure CLI in to your account.
**Why:** Terraform borrows your CLI login. No login, no deployment.

**FIX:** Use the device code flow. The browser popup login has failed on this machine before, and the device code flow works every time. You type a short code on a web page instead.

```powershell
az login --use-device-code
```

Follow the message: open the web address it shows, type the code, and sign in.

If you have more than one subscription, list them and pick the one for this lab.

```powershell
az account list --output table
```

```powershell
az account set --subscription "Azure subscription 1"
```

**NOTE:** Use the subscription name exactly as it appears in your list. It may not be "Azure subscription 1".

**Verify:**

```powershell
az account show --query "{name:name, id:id}" --output table
```

You should see the subscription you picked.

## Phase 2 - Create the Project Files

**What:** Make four empty files: `main.tf`, `variables.tf`, `outputs.tf`, and `terraform.tfvars`.
**Why:** Terraform reads every `.tf` file in the folder. Splitting them keeps each file short: `variables.tf` is the list of blanks, `terraform.tfvars` fills the blanks in, `main.tf` builds things, and `outputs.tf` prints useful results.

**VS Code:** Click each file name in the Explorer sidebar to create and edit it. Right-click an empty space in the sidebar, choose New File, and type the name. No commands needed.

**Verify:**

```powershell
Get-ChildItem *.tf, *.tfvars
```

You should see all four names listed.

## Phase 3 - variables.tf and terraform.tfvars

**What:** Declare four inputs: your name, the region, the alert email, and the budget start date.
**Why:** Resource names must be unique across Azure, so your name goes into every one. The email lives in a separate file so it never gets published.

**VS Code:** Click `variables.tf` in the sidebar and paste this in.

```hcl
variable "yourname" {
  description = "Your name, lowercase, no spaces. Used to make resource names unique."
  type        = string
}

variable "location" {
  description = "Azure region to deploy into."
  type        = string
  default     = "East US"
}

variable "alert_email" {
  description = "Email address to receive cost alert notifications."
  type        = string
}

variable "budget_start_date" {
  description = "First day of the current (or a future) month, in RFC3339 format. Azure rejects any other day."
  type        = string
  default     = "2026-10-01T00:00:00Z"
}

variable "tags" {
  type = map(string)
  default = {
    project     = "cost-dashboard"
    environment = "dev"
    managed_by  = "terraform"
  }
}
```

**FIX:** The original guide had a hard-coded budget start date of `2026-03-01`. That date is in the past, and Azure only accepts the first day of the current month or a future month. This version makes the date an input with a default of `2026-10-01` so you can change it without touching `main.tf`. If you run this lab in a later month, change the default.

Now click `terraform.tfvars` and paste this in. Use your own email.

```hcl
# Copy this file to terraform.tfvars and fill in your own values.
# terraform.tfvars is in .gitignore so your email never reaches GitHub.
yourname    = "giovanni"
location    = "East US"
alert_email = "you@example.com"
```

**SECURITY:** `terraform.tfvars` is listed in `.gitignore`, so Git will not publish it. The repo includes `terraform.tfvars.example` with a fake email so other people can see the shape.

## Phase 4 - main.tf, One Piece at a Time

**VS Code:** Click `main.tf` and add each block below in order, one under the other.

### 4a. Provider and subscription lookup

**What:** Tell Terraform to use the Azure plugin and read who you are logged in as.
**Why:** The plugin (called a provider) is what knows how to talk to Azure. The lookup gives Terraform your subscription ID, which the budget and diagnostic setting need.

```hcl
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}
```

```hcl
# Reads your current az login session (subscription ID and tenant ID)
data "azurerm_client_config" "current" {}
```

### 4b. Resource group

**What:** Create the box that holds the project.
**Why:** Every Azure resource has to live in a resource group. Deleting the group later cleans up everything inside it.

```hcl
# The folder that holds everything for this project
resource "azurerm_resource_group" "main" {
  name     = "rg-cost-dashboard-${var.yourname}"
  location = var.location
  tags     = var.tags
}
```

### 4c. Log Analytics workspace

**What:** Create the place logs are stored and searched.
**Why:** The activity log needs somewhere to land. `PerGB2018` means you pay only for the data you send, and `retention_in_days = 30` deletes data after 30 days, which keeps cost near zero.

```hcl
# Central place where logs are stored and queried
resource "azurerm_log_analytics_workspace" "main" {
  name                = "law-cost-${var.yourname}"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = var.tags
}
```

### 4d. Action group

**What:** Create the list of who gets told when an alert fires.
**Why:** You define it once and attach it to as many alerts as you want. `short_name` must be 12 characters or fewer. `use_common_alert_schema = true` makes the email format the same for every alert type.

```hcl
# Who gets told when an alert fires (short_name must be 12 characters or less)
resource "azurerm_monitor_action_group" "email_alerts" {
  name                = "ag-cost-alerts-${var.yourname}"
  resource_group_name = azurerm_resource_group.main.name
  short_name          = "costalerts"

  email_receiver {
    name                    = "owner-email"
    email_address           = var.alert_email
    use_common_alert_schema = true
  }

  tags = var.tags
}
```

### 4e. Budget with three alert levels

**What:** Create the $200 monthly budget with alerts at 25%, 50%, and 100% of it.
**Why:** 25% of $200 is $50, 50% is $100, and 100% is $200. `contact_groups` is what connects each alert to the action group, which is what actually sends the email.

```hcl
# The $200 monthly budget, with alerts at 25% ($50), 50% ($100) and 100% ($200)
resource "azurerm_consumption_budget_subscription" "main" {
  name            = "budget-cost-${var.yourname}"
  subscription_id = "/subscriptions/${data.azurerm_client_config.current.subscription_id}"

  amount     = 200
  time_grain = "Monthly"

  time_period {
    start_date = var.budget_start_date
  }

  notification {
    enabled        = true
    threshold      = 25
    operator       = "GreaterThan"
    threshold_type = "Actual"

    contact_groups = [azurerm_monitor_action_group.email_alerts.id]
  }

  notification {
    enabled        = true
    threshold      = 50
    operator       = "GreaterThan"
    threshold_type = "Actual"

    contact_groups = [azurerm_monitor_action_group.email_alerts.id]
  }

  notification {
    enabled        = true
    threshold      = 100
    operator       = "GreaterThan"
    threshold_type = "Actual"

    contact_groups = [azurerm_monitor_action_group.email_alerts.id]
  }
}
```

**WHAT THIS MEANS:** The budget does the alerting. There are no separate alert rules in this build, even though the original guide's diagram listed three.
- `time_grain = "Monthly"` resets the envelope on the 1st, the same way Azure bills.
- `threshold_type = "Actual"` means real spend, not a forecast.
- `GreaterThan` means the buzz happens when spending crosses the line going up.

**FIX:** The original guide passed the bare subscription ID. This version passes the full `/subscriptions/...` form that the Terraform 3.x provider documents for budgets. If `terraform plan` complains about the format, switch it back to the bare ID and write down which form worked in your build notes.

### 4f. Logic App

**What:** Create an empty Logic App.
**Why:** A Logic App is a low-code automation: when something happens, do something else. Terraform makes the container. You build the steps in the portal designer in Phase 7, because workflow steps are easier to build and test visually.

```hcl
# The Logic App container. The trigger and email step are built in the portal designer.
resource "azurerm_logic_app_workflow" "cost_alert" {
  name                = "la-cost-alert-${var.yourname}"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.tags
}
```

### 4g. Diagnostic setting

**What:** Send the subscription's activity log to Log Analytics.
**Why:** The activity log records who created or deleted what, and when. Without this setting, Log Analytics has nothing to show.

```hcl
# Sends the subscription activity log into Log Analytics
resource "azurerm_monitor_diagnostic_setting" "subscription_logs" {
  name                       = "diag-sub-to-law"
  target_resource_id         = "/subscriptions/${data.azurerm_client_config.current.subscription_id}"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  enabled_log {
    category = "Administrative"
  }

  enabled_log {
    category = "Security"
  }

  enabled_log {
    category = "Policy"
  }
}
```

**Verify:** Save the file (Ctrl+S) and check the formatting.

```powershell
terraform fmt -check
```

No output means everything is already formatted.

## Phase 5 - outputs.tf

**What:** Print four useful values after the deploy.
**Why:** It saves you from hunting through the portal.

```hcl
output "resource_group_name" {
  value = azurerm_resource_group.main.name
}

output "log_analytics_workspace_id" {
  value = azurerm_log_analytics_workspace.main.id
}

output "logic_app_access_endpoint" {
  description = "Base endpoint only. The signed HTTP POST URL you need comes from the Logic App designer trigger."
  value       = azurerm_logic_app_workflow.cost_alert.access_endpoint
}

output "action_group_id" {
  value = azurerm_monitor_action_group.email_alerts.id
}
```

**FIX:** The original guide named the third output `logic_app_callback_url`. That value is only the base address of the Logic App, not the signed URL that Azure Monitor needs. It is renamed `logic_app_access_endpoint` so you do not paste the wrong thing in Phase 7. The real URL comes from the designer.

## Phase 6 - Deploy

**What:** Download the Azure plugin, check the files, preview the changes, and build.
**Why:** `plan` is a free preview. You read it before you spend anything.

```powershell
terraform init
```

You should see: Terraform has been successfully initialized.

```powershell
terraform validate
```

You should see: Success! The configuration is valid.

```powershell
terraform plan
```

You should see **6 to add**: the resource group, workspace, action group, budget, Logic App, and diagnostic setting.

```powershell
terraform apply
```

Type `yes` when asked. It takes about 2 to 3 minutes.

**Verify:**

```powershell
terraform output
```

```powershell
az resource list --resource-group $RG --output table
```

**NOTE:** The list shows 3 resources: the workspace, the action group, and the Logic App. The budget and the diagnostic setting belong to the whole subscription, not the resource group, so they will not appear here.

## Phase 7 - Build the Logic App Steps and Connect It

**What:** Give the Logic App a trigger and an email step, then register it with the action group.
**Why:** Right now the Logic App is an empty box. It needs a front door (the trigger URL) and an action (send an email). The action group then needs the address of that front door.

### Portal path

1. In the Azure portal, open your resource group `rg-cost-dashboard-giovanni`.
2. Click the Logic App `la-cost-alert-giovanni`.
3. In the left menu, click **Logic app designer**.
4. Click **Add a trigger**, search for **HTTP**, and choose **When a HTTP request is received**.
5. Click Save. The **HTTP POST URL** now appears in the trigger. Copy it.
6. Click **+ New step**, search for **Office 365 Outlook**, and choose **Send an email (V2)**.
7. Sign in when asked.
8. Fill in To (your alert email), Subject (`Azure Cost Alert - Budget Threshold Reached`), and Body (Add dynamic content, then the Body from the HTTP trigger).
9. Click Save.

**NOTE:** The Office 365 Outlook step needs a work or school mailbox. A tenant that only has a personal sign-in may fail here. If it does, use the Gmail or another email connector instead and write that in your build notes.

**SECURITY:** The HTTP POST URL contains a secret signature (the `sig=` part). Anyone who has it can trigger your Logic App. Never paste it into a file, a screenshot, or a post.

### Azure CLI path

Get the Logic App's ID.

```powershell
$LA_ID = az resource show --resource-group $RG --name $LA --resource-type "Microsoft.Logic/workflows" --query id --output tsv
```

Paste the URL you copied. The input is hidden as you paste.

```powershell
$CALLBACK = Read-Host "Paste the HTTP POST URL" -MaskInput
```

**NOTE:** `-MaskInput` needs PowerShell 7.1 or newer. If it says the parameter is not recognized, you are in Windows PowerShell 5.1. Run the same line without `-MaskInput`. Do not swap in `-AsSecureString`, because `az` would receive the text `System.Security.SecureString` instead of your URL.

Register the Logic App with the action group.

```powershell
az monitor action-group update --name $AG --resource-group $RG --add-action logicapp la-webhook $LA_ID $CALLBACK --output none
```

**FIX:** The original guide put the Logic App name in this command twice, which gives the command one value too many. The pattern is `logicapp NAME RESOURCE_ID CALLBACK_URL`, so only one name (`la-webhook`) is used. `--output none` keeps the secret URL from printing back on screen.

Clear the secret from your terminal.

```powershell
Remove-Variable CALLBACK
```

**Verify:**

```powershell
az monitor action-group show --name $AG --resource-group $RG --query "{emails:emailReceivers[].emailAddress, logicApps:logicAppReceivers[].name}" --output json
```

You should see your email under `emails` and `la-webhook` under `logicApps`.

**Test it:** In the portal, open the action group `ag-cost-alerts-giovanni`, click **Test action group**, pick a sample type, and run it. This proves the email path works without waiting for real spend.

## Phase 8 - Build the Dashboard in Azure Workbooks

**What:** Make a saved dashboard in the Azure portal.
**Why:** This is the part the business owner actually looks at.

1. In the portal, search for **Monitor** and open it.
2. In the left menu, click **Workbooks**, then **+ New**.
3. Click **+ Add**, then **Add query**.
4. Set Data source to **Azure Resource Graph** and paste this query:

```
resourcecontainers
| where type == "microsoft.resources/subscriptions/resourcegroups"
| project resourceGroup, location
```

5. Click **Run Query** to check it works, then **Done Editing**.
6. Click **+ Add**, then **Add metric**. Pick your subscription and look for **Cost Management** as the resource type.
7. Click **Save**, name it `Cost Visibility Dashboard`, choose your resource group, and click Apply.

**NOTE:** The Resource Graph query above lists resource groups, not dollars. The portal's metric picker may also not offer Cost Management as a resource type. Write down exactly what you see. If dollars are not available there, use the portal's **Cost analysis** page for the actual spend and note it in your build notes.

## Phase 9 - Final Verification

Work down this list. Every line should be true.

- Resource group `rg-cost-dashboard-giovanni` exists
- Budget `budget-cost-giovanni` shows in Cost Management, then Budgets
- Action group `ag-cost-alerts-giovanni` exists in Monitor, then Alerts, then Action groups
- Logic App `la-cost-alert-giovanni` shows Enabled, and its designer shows an HTTP trigger plus a Send email step
- Log Analytics workspace `law-cost-giovanni` exists
- The workbook is saved and visible in Monitor, then Workbooks

```powershell
az consumption budget show --budget-name $BUDGET --output table
```

**NOTE:** If this command is not found or shows as preview in your CLI, check the budget in the portal instead.

## Troubleshooting

| Error or symptom | Cause | Fix |
|---|---|---|
| `BudgetStartDateInvalid` (expected) | The start date was not the first day of the current or a future month. | Set `budget_start_date` in `variables.tf` to the first of this month, then run `terraform apply` again. |
| `AuthorizationFailed` on the budget (expected) | Your account lacks permission to create budgets. | Run `az role assignment create --role "Cost Management Contributor" --assignee $(az ad signed-in-user show --query id --output tsv) --scope /subscriptions/$(az account show --query id --output tsv)`. |
| Outlook step will not sign in (expected) | Office 365 needs a work or school mailbox, and sign-in must happen in the portal. | Sign in through the designer. Terraform cannot do this step. If the tenant has no mailbox, use a Gmail connector. |
| `az monitor action-group update` rejects the arguments (expected) | The original guide's command had an extra name. | Use `--add-action logicapp la-webhook $LA_ID $CALLBACK` exactly as in Phase 7. |
| No alert email arrives (expected) | Budget alerts only fire after real spend crosses a line. | Use **Test action group** in the portal to prove the email path. |
| `terraform destroy` stops because the group still has resources (expected) | The workbook and the Outlook connection were made in the portal, so Terraform does not know about them. | Follow the Clean Up section: list the group, delete the extras, then destroy. |

## Clean Up

**What:** Remove everything so nothing keeps billing.
**Why:** Terraform only deletes what it created. The workbook and the email connection were made by hand in the portal, so look first.

```powershell
az resource list --resource-group $RG --output table
```

Anything listed that is not the workspace, action group, or Logic App was made in the portal (the workbook and the Office 365 connection). Delete those in the portal first: open each one and click Delete.

```powershell
terraform destroy
```

Type `yes` when asked.

**Verify:**

```powershell
az group exists --name $RG
```

You should see `false`.

## What You Built

| Resource | Name | Purpose |
|---|---|---|
| Resource group | `rg-cost-dashboard-giovanni` | Holds the project |
| Budget | `budget-cost-giovanni` | $200 per month, alerts at $50, $100, $200 |
| Action group | `ag-cost-alerts-giovanni` | Email plus Logic App webhook |
| Logic App | `la-cost-alert-giovanni` | Formats and sends the alert email |
| Log Analytics | `law-cost-giovanni` | Stores 30 days of activity data |
| Diagnostic setting | `diag-sub-to-law` | Sends the activity log to Log Analytics |
| Workbook | Cost Visibility Dashboard | Dashboard in Azure Monitor (portal only) |
