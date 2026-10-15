# Azure Essentials Project 01 - Azure Cost Visibility Dashboard (SOP)

**Before you load your terminal:** every command in this SOP needs the variables from Step 0. Open a new VS Code terminal and run `. .\set-vars.ps1` first. If you are not signed in, run `az login --use-device-code` again.

**SECURITY:** Your screenshots show your subscription ID and your email address. Blur both before they go into the README, a LinkedIn post, or the Loom video. Never show the Logic App HTTP POST URL.

**Time:** 3 to 4 hours  |  **Difficulty:** Beginner  |  **Cost:** close to zero for a short lab (budgets and action groups are free; Log Analytics and Logic Apps bill per use)

## Real Findings From This Build

**What:** The things that actually went wrong while building this lab, and how each one was fixed.
**Why:** Real problems and real fixes are what make a lab believable. Every item below happened on this build. Read this before Phase 7 so you do not lose an hour to them.

| # | What happened | Why it happened | What fixed it |
|---|---|---|---|
| 1 | `Set-ExecutionPolicy` error: "set-vars.ps1 is not digitally signed" | Windows blocks unsigned scripts by default | Run `Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass` in that terminal. It only lasts until you close the terminal |
| 2 | `az monitor action-group show` printed "Missing required field: -n" | The command was typed without `--name` and `--resource-group`, so the CLI had nothing to look up | Load the variables first with `. .\set-vars.ps1`, then run the command with `--name $AG --resource-group $RG` |
| 3 | `terraform.tfvars` had the contents of `variables.tf` pasted into it | Copied the wrong file | Replace the file with only `yourname` and `alert_email` lines |
| 4 | Office 365 Outlook returned **401 Unauthorized** | The tenant has no Exchange Online mailbox, so there is nothing for the connector to sign in to | Use the Gmail connector instead |
| 5 | Gmail returned **403 insufficient scopes** | The first sign-in did not tick every permission box on Google's consent screen | Sign in again and tick **all** the permission boxes |
| 6 | The Logic App URL variable stayed empty | `Read-Host` showed a prompt label, and the URL was pasted in as the label text instead of at the prompt | Type the prompt, press Enter, then paste at the hidden input. Better: skip this path and use the portal route in Phase 7 |
| 7 | `az monitor action-group update` created a broken receiver | On Windows, the signed URL contains `&`, and `cmd.exe` splits the command at every `&`, so only the first part of the URL reached Azure | Register the Logic App through the portal (Phase 7, portal route). Do not use the CLI route on Windows |
| 8 | The signed Logic App URL showed up in a chat three times | It was pasted while troubleshooting | The Logic App access key was rotated once. After any rotation, re-save the action group's Logic App action, because it stores the signed URL |
| 9 | Terraform now disagrees with Azure | The Logic App receiver, the workbook, and the Gmail connection were all added by hand in the portal | Do not run `terraform apply` again. See "Terraform Drift" below and the Clean Up section |
| 10 | The workbook's workspace picker showed "0 selected" and "No items of this type" | The picker only searches the workbook's own scope until you ask for more | Tick **Load all subscriptions**, or open the workbook from the workspace's own **Monitoring, then Workbooks** menu so the scope is already set |
| 11 | The Visualization list had no option called Table | Workbooks calls the table view **Grid** | Pick **Grid** |
| 12 | No way to chart dollar spend in Logs | Cost data is not in Log Analytics, and the `AzureActivity` table holds operations, not prices | Chart activity, list resource groups, and link to Cost Analysis for dollars |
| 13 | The Resource Graph grid listed every resource group in the subscription | `resourcecontainers` returns the whole subscription | Add `| where resourceGroup contains "cost-dashboard"` before the `project` line |
| 14 | The action group email verification link said "Verification failed, link is no longer valid" | The link expires, and saving the action group again can invalidate older ones | Click **Resend verification emails** on the action group page and use the newest message. The status changes from Pending to Verified |
| 15 | The budget list on the resource group page said "You do not have any budgets" | Budgets belong to the subscription, not the resource group | Switch the Cost Management scope to the subscription |

### Terraform Drift (portal changes versus infrastructure as code)

**What:** Terraform wrote the action group with only the email receiver. The Logic App receiver was added later in the portal.
**Why this matters:** Terraform compares its state file to the code, not to what you did by hand. If you run `terraform plan` now, it will likely show the action group changing to **remove** the Logic App receiver, because the code does not list it. If you then run `apply`, the alert chain silently breaks.

**Rule:** After Phase 7, do not run `terraform apply`. Run only `terraform destroy` at Clean Up. For a production build, you would add the receiver to `main.tf` (a `logic_app_receiver` block) so the code and the portal agree.

## Where to Click (Portal Map)

These are the places people get lost. Each one is a real question that came up during this build.

**Azure Monitor:** Click the search bar at the top of the portal, type `Monitor`, and pick **Monitor** from the Services results. In the left menu you will see Activity log, Alerts, Metrics, Logs, and **Workbooks**.

**Workbooks (shortcut, the one that worked):** Open your Log Analytics workspace `law-cost-giovanni` and click **Workbooks** in its left menu. A workbook started from there already points at your workspace, so you skip choosing a scope.

**Action group Actions table:** Search for **Action groups**, open `ag-cost-alerts-giovanni`, and click the **Actions** tab. The table shows Type, Name, Value, and Managed identity. For this build it shows `Logic App`, `la-webhook`, `la-cost-alert-giovanni`, `None`. Take screenshots of the table only. Do not click into the row, because the detail pane can show the signed URL.

**Logic App Run history:** Open the resource group, click `la-cost-alert-giovanni`, then click **Run history** (the tab next to Get started and Trigger history). Press Refresh if it is empty, because it can lag about 30 seconds.

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

**NOTE:** The list shows 3 resources: the workspace, the action group, and the Logic App. The budget and the diagnostic setting belong to the whole subscription, not the resource group, so they will not appear here. Your screenshot of the resource group matches this. After Phase 7 you will also see a Gmail connection resource named `gmail`, because the Logic App created it when you signed in.

## Phase 7 - Build the Logic App Steps and Connect It

**What:** Give the Logic App a trigger and an email step, then register it with the action group.
**Why:** Right now the Logic App is an empty box. It needs a front door (the trigger URL) and an action (send an email). The action group then needs the address of that front door.

### Portal path

1. In the Azure portal, open your resource group `rg-cost-dashboard-giovanni`.
2. Click the Logic App `la-cost-alert-giovanni`.
3. In the left menu, click **Logic app designer**.
4. Click **Add a trigger**, search for **HTTP**, and choose **When a HTTP request is received**.
5. Click **Save** at the top. The **HTTP POST URL** says "URL will be generated after save" until you do. After saving, copy the URL.
6. Click the **+** under the trigger, then **Add an action**. In the search box, look for the email connector you can sign in to (see the NOTE below), and choose **Send email (V2)**.
7. Sign in when asked and allow the connection.
8. Fill in To (your alert email), Subject (`Azure Cost Alert - Budget Threshold Reached`), and Body. Click in the Body box, choose **Add dynamic content**, and pick the **Body** from the HTTP trigger. If the Body box stays empty, the email arrives blank.
9. Click **Save** again.

**NOTE:** In this build, Office 365 Outlook was tried first and failed with a **401** because the tenant has no Exchange Online mailbox. Gmail was used instead. The **Gmail** connector, **Send email (V2)**, works with a personal Google account. The first Gmail sign-in then failed with a **403 insufficient scopes**, because not every permission box was ticked. Sign in again and tick **all** the boxes. Both connectors look the same in the designer, so the steps above are identical.

**NOTE:** The designer shows a blue banner saying "You are using the previous Logic Apps experience." That is normal for a Consumption Logic App. Do not click Switch to preview experience in the middle of the lab, because the screens change.

**SECURITY:** The HTTP POST URL contains a secret signature (the `sig=` part). Anyone who has it can trigger your Logic App. Never paste it into a file, a screenshot, or a post.

### Azure CLI path (did not work on Windows in this build)

**WARNING:** On Windows, `az` hands the command through `cmd.exe`, which splits the signed URL at every `&`. Azure received a cut-off URL and saved a broken receiver. This route can work on Mac or Linux. On Windows, skip to the portal route below.

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

### Portal route (this is what worked)

**What:** Add the Logic App to the action group by clicking, with no command involved.
**Why:** The portal sends the URL to Azure directly, so nothing splits it.

1. Search for **Action groups** and open `ag-cost-alerts-giovanni`.
2. Click **Edit action group**, then the **Actions** tab.
3. Set **Action type** to **Logic App**, name it `la-webhook`, and pick `la-cost-alert-giovanni`.
4. Leave the **Identity** dropdown on **Select**. It is optional and not needed here.
5. Click **OK**, then **Save changes**. You should see a green **Action group updated successfully** message.

If an earlier CLI attempt left a broken receiver, delete that row first, then add the new one.

**Verify (both routes):**

**NOTE:** Run `. .\set-vars.ps1` first. Without `$AG` and `$RG` loaded, the command fails with "Missing required field: -n". Use this filtered version only. A plain `show` prints the signed callback URL.

```powershell
az monitor action-group show --name $AG --resource-group $RG --query "{emails:emailReceivers[].emailAddress, logicApps:logicAppReceivers[].name}" --output json
```

You should see your email under `emails` and `la-webhook` under `logicApps`.

### Step 7b - Verify the action group email

**What:** Click the confirmation link Azure emailed to your alert address.
**Why:** Azure will not send alerts to an address until its owner confirms it. Your action group page currently shows the email as **Pending**, which means the budget alerts would go nowhere.

1. Open the inbox for the alert email and find the message from Microsoft Azure about the action group. Check spam if it is not there.
2. Click the verification link in that message.
3. In the portal, open `ag-cost-alerts-giovanni`. The email row should change from Pending to **Verified**. If it still says Pending, click **Resend verification emails** and try again.

**NOTE:** The Logic App path does not need verification. Only the plain email receiver does.

### Step 7c - Test it

**What:** Fire a fake alert through the action group.
**Why:** Real budget alerts only fire after real spending, so this is the only way to prove the chain works today.

1. In the portal, open the action group `ag-cost-alerts-giovanni` and click **Test**.
2. Pick **Budget** or **Cost** if offered, otherwise any sample type, and click **Test**.
3. Wait one or two minutes. When it finishes, both rows should say **Success**. You should get a plain alert email, and a second email sent by the Logic App.

**What the tests showed:**
- **Oct 12, first test:** the Logic App row said **Success** (3 seconds), and the Email row said **Unknown**. That is what an unverified email address looks like. Verifying the address in Step 7b fixed it.
- **Oct 13, second test (9:30 PM):** both emails arrived. The action group sent "Delivery Confirmation: This is a sample budget alert from Azure Monitor Action Groups" (sample alert name `test-budgetAlertRule`, Sev4, fake IDs). The Logic App sent "Azure Cost Alert - Budget Threshold Reached". Run history shows a **Succeeded** run for 10/13 9:30 PM (2.31 seconds), with two earlier Succeeded runs from Oct 12.

**NOTE:** The Logic App email body is the raw JSON the action group sent. It proves the chain works. To make it readable, pick individual fields from the dynamic content list instead of the whole Body.

4. Open the Logic App, then **Overview**, then **Run history**. You should see one run marked **Succeeded**.

If the Logic App run fails, click the run and open the failed step. The most common cause is the Gmail sign-in expiring, which you fix under API connections.

## Phase 8 - Build the Dashboard in Azure Workbooks

**What:** Make a saved dashboard in the Azure portal.
**Why:** This is the part the business owner actually looks at. It is the one piece Terraform does not build, so you make it by hand.

**Prerequisite:** Phase 7 is finished. The activity log chart in Step 8c needs the diagnostic setting from Terraform, and it can take 15 to 30 minutes after the deploy before the first rows show up. You deployed on Oct 9, so the data should already be there.

### Step 8a - Open a new workbook

**What:** Open a blank workbook, which is like a blank page for your dashboard.
**Why:** You need an empty page first, because every chart and table in Steps 8b to 8d gets added to it.

1. In the portal, search for **Monitor** and open it.
2. In the left menu, click **Workbooks**, then **+ New**.

### Step 8b - Add a Resource Graph table

**What:** A table that lists the resource groups in the subscription.
**Why:** It proves the workbook can read from your subscription.

1. Click **+ Add**, then **Add query**.
2. Set Data source to **Azure Resource Graph** and paste this query:

```
resourcecontainers
| where type == "microsoft.resources/subscriptions/resourcegroups"
| project resourceGroup, location
```

3. Click **Run Query** to check it works, then **Done Editing**.

### Step 8c - Add an activity log chart

**What:** A chart of what happened in your subscription over the last 7 days.
**Why:** This reads the data your diagnostic setting sends to Log Analytics, so it shows the whole pipeline working from end to end.

1. Click **+ Add**, then **Add query**.
2. Set Data source to **Logs**, Resource type to **Log Analytics**, and pick the workspace `law-cost-giovanni`.
3. Paste this query:

```
AzureActivity
| where TimeGenerated > ago(7d)
| summarize Operations = count() by bin(TimeGenerated, 1d)
| order by TimeGenerated asc
```

4. Set Visualization to **Bar chart** or **Time chart**, click **Run Query**, then **Done Editing**.

**NOTE:** If the result says the table does not exist or is empty, wait 15 minutes and run it again. If it is still empty after an hour, open Monitor, then Activity log, then Export Activity Logs, and confirm the setting `diag-sub-to-law` points at your workspace.

### Step 8d - Add a link to real spending

**What:** A text tile that sends the owner to the Cost analysis page.
**Why:** Workbooks cannot read dollar amounts the way Cost analysis can. The Resource Graph query above lists resource groups, not dollars, and the metric picker may not offer Cost Management as a resource type. Rather than fight that, link to the page that has the real numbers.

1. Click **+ Add**, then **Add text**.
2. Type: `For actual spend, open Cost Management, then Cost analysis.`
3. Click **Done Editing**.

Write down exactly what you see if you try **Add metric** and Cost Management is missing. That is a real finding for your build notes.

### Step 8e - Save it

**What:** Save the dashboard into your resource group.
**Why:** A workbook you do not save disappears when you close the tab. Saving keeps your work and lets the business owner open it later.

1. Click **Save** at the top.
2. Name it `Cost Visibility Dashboard`, pick your subscription and resource group `rg-cost-dashboard-giovanni`, and click **Apply**.

**Verify:** In Monitor, then Workbooks, you should see `Cost Visibility Dashboard` listed. Open it and confirm both queries show results.

**NOTE:** A workbook you save into the resource group is a real resource that Terraform does not know about. This is why Clean Up has you look at the group before running `terraform destroy`.

## Phase 9 - Final Verification

**What:** A final checklist that proves every piece of the lab exists and works.
**Why:** A lab is only done when you have checked it. It is much easier to find a broken piece now than later, in front of a camera or an interviewer.

Work down this list. Every line should be true. Check each box as you go.

- [ ] Resource group `rg-cost-dashboard-giovanni` exists
- [ ] Budget `budget-cost-giovanni` shows in Cost Management, then Budgets, with alerts at 25, 50, and 100 percent
- [ ] Action group `ag-cost-alerts-giovanni` exists in Monitor, then Alerts, then Action groups
- [ ] The action group email shows **Verified**, not Pending
- [ ] Logic App `la-cost-alert-giovanni` shows Enabled, and its designer shows an HTTP trigger plus a Send email step
- [ ] Test action group sent an email, and the Logic App run history shows Succeeded
- [ ] Log Analytics workspace `law-cost-giovanni` exists
- [ ] The workbook is saved and visible in Monitor, then Workbooks

```powershell
az consumption budget show --budget-name $BUDGET --output table
```

**NOTE:** If this command is not found or shows as preview in your CLI, check the budget in the portal instead.

## Troubleshooting

**What:** A list of the errors and surprises that came up, with the cause and the fix for each.
**Why:** Errors are normal in cloud work. If you know the usual causes, you can fix them in minutes instead of hours.

| Error or symptom | Cause | Fix |
|---|---|---|
| `BudgetStartDateInvalid` (expected, did not happen: the budget deployed with the 2026-10-01 default) | The start date was not the first day of the current or a future month. | Set `budget_start_date` in `variables.tf` to the first of this month, then run `terraform apply` again. |
| `AuthorizationFailed` on the budget (expected, did not happen) | Your account lacks permission to create budgets. | Run `az role assignment create --role "Cost Management Contributor" --assignee $(az ad signed-in-user show --query id --output tsv) --scope /subscriptions/$(az account show --query id --output tsv)`. |
| Office 365 Outlook step will not work (happened in this build) | Office 365 Outlook needs a work or school mailbox, and a personal-only sign-in cannot use it. | Use the **Gmail** connector, **Send email (V2)**, instead. Sign in through the designer. Terraform cannot do this step. |
| HTTP POST URL box says "URL will be generated after save" (happened in this build) | The trigger has not been saved yet. | Click **Save** in the designer, then copy the URL that appears. |
| Test action group shows the Email row as **Unknown** while the Logic App row shows Success (happened in this build) | The email receiver is still unverified, so Azure cannot confirm delivery. | Complete Step 7b, then run the test again. |
| Action group email says **Pending** (happened in this build) | Azure waits for you to click the verification link it emailed. | Open the email, click the link, then refresh the page. Use **Resend verification emails** if it is missing. |
| `az monitor action-group show` says `Missing required field: -n` (happened in this build) | The command ran without `--name` and `--resource-group`, or the variables were never loaded in this terminal. | Run `. .\set-vars.ps1`, then run the command with `--name $AG --resource-group $RG`. |
| `az monitor action-group update` saves a broken Logic App receiver (happened in this build) | On Windows, `cmd.exe` splits the signed URL at every `&`. | Delete the broken receiver and re-add the Logic App through the portal (Phase 7, portal route). |
| Gmail step fails with 403 insufficient scopes (happened in this build) | Not every permission box was ticked on Google's consent screen. | Sign in to the connection again and tick all the permission boxes. |
| Office 365 Outlook step fails with 401 (happened in this build) | The tenant has no Exchange Online mailbox. | Use the Gmail connector. |
| `terraform plan` wants to remove the Logic App receiver (expected) | The receiver was added in the portal, so the code does not list it. | Do not run `apply`. Go straight to Clean Up when you finish. See Terraform Drift. |
| `az monitor action-group update` rejects the arguments (expected, did not happen: the command ran and the check shows `la-webhook`) | The original guide's command had an extra name. | Use `--add-action logicapp la-webhook $LA_ID $CALLBACK` exactly as in Phase 7. |
| No alert email arrives (expected) | Budget alerts only fire after real spend crosses a line, and the plain email receiver must be verified first. | Verify the email (Step 7b), then use **Test** in the portal (Step 7c) to prove the email path. |
| Workbook chart says the `AzureActivity` table is missing or empty (expected) | The diagnostic setting was only just created, so Log Analytics has no rows yet. | Wait 15 to 30 minutes and run the query again. Confirm `diag-sub-to-law` points at `law-cost-giovanni`. |
| `terraform destroy` stops because the group still has resources (expected) | The workbook and the Gmail connection were made in the portal, so Terraform does not know about them. | Follow the Clean Up section: list the group, delete the extras, then destroy. |

## Clean Up

**What:** Remove everything so nothing keeps billing.
**Why:** Terraform only deletes what it created. The workbook and the email connection were made by hand in the portal, so look first.

```powershell
az resource list --resource-group $RG --output table
```

Anything listed that is not the workspace, action group, or Logic App was made in the portal (the workbook and the Gmail connection named `gmail`). Delete those in the portal first: open each one and click Delete.

**NOTE:** Do not run `terraform apply` before this point. The Logic App receiver on the action group was added in the portal, so Terraform would try to remove it. `terraform destroy` is safe, because it deletes the whole group either way.

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
| Logic App | `la-cost-alert-giovanni` | HTTP trigger plus a Gmail Send email (V2) step that sends the alert email |
| Log Analytics | `law-cost-giovanni` | Stores 30 days of activity data |
| Diagnostic setting | `diag-sub-to-law` | Sends the activity log to Log Analytics |
| Workbook | Cost Visibility Dashboard | Dashboard in Azure Monitor (portal only) |

## Acronyms and Terms

**What:** A list of the short names and special words used in this lab.
**Why:** Cloud work is full of abbreviations. If a word looks strange, look it up here instead of guessing. The short names come first, then the special words.

| Term | Stands for | In plain words |
|---|---|---|
| AG | Action Group | A short name used in commands. `$AG` holds the name of your action group, so you do not have to retype it. |
| API | Application Programming Interface | A set of rules that lets one program talk to another. Terraform uses Azure's API to build things for you. |
| CLI | Command-Line Interface | A way to control a program by typing commands instead of clicking. The Azure CLI command is `az`. |
| GB | Gigabyte | A measure of how much data is stored. |
| HTTP | HyperText Transfer Protocol | The language that web pages and web services use to talk to each other. |
| ID | Identification | A unique number or name that points to exactly one thing, like a subscription ID. |
| IT | Information Technology | Computers, networks, and the people who keep them working. |
| JSON | JavaScript Object Notation | A neat text format that stores information as labels and values. |
| POST | HTTP POST | A kind of web message that carries information to an address. Azure sends a POST to hand the alert to the Logic App. |
| RG | Resource Group | A short name used in commands. `$RG` holds the name of your resource group. |
| SOP | Standard Operating Procedure | A step by step instruction sheet that anyone can follow. |
| URL | Uniform Resource Locator | A web address. |
| V2 | Version 2 | The second version of something. "Send email (V2)" is the newer version of the Send email step. |
| VS Code | Visual Studio Code | A free program for writing and editing code and text files. |
| Azure | - | Microsoft's cloud. That means computers and services you rent over the internet instead of owning. |
| Subscription | - | Your Azure account for billing. Everything you build is billed to it. |
| Tenant | - | Your organization's private space inside Microsoft's sign-in system. |
| Resource group | - | A folder that holds all the pieces of one project, so you can manage or delete them together. |
| Terraform | - | A tool where you write what you want in text files and it builds it for you. |
| Infrastructure as code | - | Describing your cloud setup in files, so you can rebuild the exact same thing any time. |
| Budget | - | A monthly spending limit in Azure. It warns you when spending gets close. It does not stop the spending. |
| Alert | - | A message that says something needs your attention, like spending just hit $50. |
| Action group | - | A list of who or what to tell when an alert goes off. |
| Logic App | - | A small automation that does steps for you. Here, when it gets the alert, it sends an email. |
| Connector | - | A ready-made piece that lets a Logic App talk to another service, like Gmail. |
| Webhook | - | A web address that another program can send a message to, so it starts something. |
| Signed URL | - | A web address with a secret password built into it (the `sig=` part). Anyone who has it can use it, so never share it. |
| Log Analytics workspace | - | A storage place where logs are kept so you can search them. |
| Diagnostic setting | - | A switch that sends activity records to the place that stores them. |
| Activity log | - | A diary of what happened in your Azure subscription. |
| Workbook | - | A dashboard page in Azure Monitor made of charts and tables. |
| Dashboard | - | One page that shows the important numbers so you can see them at a glance. |
| State file | - | Terraform's notebook of what it built (`terraform.tfstate`). Never share it, because it can hold private details. |
| Drift | - | What happens when someone changes a thing by hand in the portal, so it no longer matches the code. |
| Apply and destroy | - | `terraform apply` builds what your files describe. `terraform destroy` deletes all of it. |
| Device code sign in | - | Signing in by typing a short code on a web page, instead of using a popup window. |
| Redact | - | Covering up private details in a screenshot, so nobody can read them. |
