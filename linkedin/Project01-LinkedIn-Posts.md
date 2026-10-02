# Azure Essentials Project 01 - LinkedIn Posts

## Posting notes

- Post in this order, 2 to 3 days apart: Loom, GitHub, Learned, Different.
- LinkedIn does not accept SVG. Use the PNG copies listed under each post.
- For Posts 3 and 4, add a real screenshot as a second image.
- Replace `[Loom link]` in Post 1 before posting.
- **Posts 3 and 4 are drafted around problems the lab guide makes likely (an old budget start date, and resources made by hand in the portal). Keep each one only if it really happened to you, or swap in your real error and fix. Delete the DRAFT line at the top of each before posting.**

---

## Post 1 - Loom video

Thumbnail: `assets/thumbnails/png/post1-loom.png`
Generic alternate: `assets/thumbnails/generic/png/g1-watch.png`

Can you explain your Azure bill to your boss?

Most small businesses can't. The bill shows up full of lines like "Microsoft.Compute/virtualMachines" and nobody knows what it means or what next month looks like.

So I built the fix.

Project 1 in my Azure Essentials series is a cost visibility dashboard, all in Terraform:

A $200 monthly budget that watches real spend
Email alerts at $50, $100, and $200
A Logic App that formats the alert
A Log Analytics workspace for activity logs
A Workbook dashboard in Azure Monitor

Here's how it flows. When spend crosses a line, the budget fires an Action Group. That sends an email and calls the Logic App, so the owner hears about it in plain language instead of finding out on the invoice.

The business outcome is what matters. The owner sees the spend and hears about it before the bill is a problem. The services are just how I got there.

Five minute walkthrough here: [Loom link]

#Azure #Terraform #CloudCost #FinOps #LogicApps #AzureMonitor #CloudEngineering #DevOps #LearningInPublic #CareerPivot

---

## Post 2 - GitHub repo

Thumbnail: `assets/thumbnails/png/post2-github.png`
Generic alternate: `assets/thumbnails/generic/png/g2-github.png`

The repo for my Azure cost dashboard is live.

Clone it, run terraform apply, and you get a working cost alert system in your own subscription.

What's inside:

[x] main.tf, variables.tf, outputs.tf - six resources, no portal clicking for the infrastructure
[x] set-vars.ps1 - every name in one place
[x] A step-by-step SOP written so a beginner can follow it, with the why behind each step
[x] An animated architecture diagram
[x] Troubleshooting table with real error messages
[x] .gitignore that keeps your email and Terraform state out of GitHub

Cost: close to zero for a short lab. Time: 3 to 4 hours.

I come from radio and network infrastructure, so I wrote the SOP the way I wish labs were written for me: what you're doing, why, and how to prove it worked.

One honest note. The Logic App steps and the Workbook are built in the portal, because that's where they're easiest to build and test. The SOP walks through both.

Repo: https://github.com/Gguerra4networks/azure-cost-dashboard

Star it if it helps, and tell me what you'd add.

#Azure #Terraform #GitHub #InfrastructureAsCode #CloudCost #FinOps #AzureMonitor #CloudEngineering #LearningInPublic #HandsOnLabs

---

## Post 3 - One thing I learned

Thumbnail: `assets/thumbnails/png/post3-learned.png`
Generic alternate: `assets/thumbnails/generic/png/g3-learned.png`

DRAFT - keep only if this happened to you, and paste your exact error.

A date in the past broke my cost budget.

My Terraform plan looked fine. Then the apply failed on the budget with BudgetStartDateInvalid.

The lab guide had this line:

start_date = "2026-03-01T00:00:00Z"

Azure only accepts the first day of the current month or a future month. That March date was already months old, so the apply failed and the budget never got created.

I fixed it by turning the date into a variable in variables.tf:

variable "budget_start_date" { default = "2026-10-01T00:00:00Z" }

Now I can change it without digging through main.tf, and I re-run terraform plan to confirm.

Plan checks your syntax and types. It can't always know what the Azure budget service will accept, because that check happens when the request is actually sent.

The lesson: a clean plan does not mean Azure will accept every value. Dates, names, and regions get checked at apply time.

What's a value that passed your plan and then failed at apply?

#Azure #Terraform #InfrastructureAsCode #CloudCost #Troubleshooting #DevOps #CloudEngineering #LearningInPublic #AzureBudgets #LabLife

---

## Post 4 - What I'd do differently

Thumbnail: `assets/thumbnails/png/post4-different.png`
Generic alternate: `assets/thumbnails/generic/png/g4-different.png`

DRAFT - keep only if this happened to you, and paste your exact error.

I'd look inside the resource group before running terraform destroy.

Terraform only deletes what it created. In this lab I built the Logic App steps and the Workbook by hand in the portal. Terraform has no idea they exist, so destroy stops because the group still has resources in it.

Here's what I do now. First, see everything in the group:

az resource list --resource-group $RG --output table

Delete anything Terraform didn't create, like the workbook and the Outlook connection. Then run:

terraform destroy

Verify the group is gone:

az group exists --name $RG

It should print false.

Anything built outside Terraform is a loose end, so I write down what I made by hand while I'm making it.

It takes ten seconds per item while you're building and saves a confusing error at the end. Cleanup is part of the lab, not an afterthought, and a forgotten resource is a bill waiting to happen.

Do you track what you build outside your IaC, or find out at cleanup time?

#Azure #Terraform #InfrastructureAsCode #CloudCleanup #DevOps #AzureCLI #CloudEngineering #LearningInPublic #BestPractices #LabLife
