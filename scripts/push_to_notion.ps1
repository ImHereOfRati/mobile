<#
Simple PowerShell helper to create Notion pages from markdown files.

Usage examples:
  $env:NOTION_TOKEN = "secret"
  $env:NOTION_PARENT_PAGE_ID = "parent-page-id"
  .\scripts\push_to_notion.ps1 -Files @("docs/ai-records/background-delivery-plan.md","docs/ai-records/ui-transition-plan.md")

This script expects these env vars to be set (or you can pass them as params):
  NOTION_TOKEN - integration token with pages creation permission
  NOTION_PARENT_PAGE_ID - id of destination parent page

It creates one Notion child page per file and converts simple markdown headings (#, ##, ###) into heading blocks.
#>

[CmdletBinding()]
param(
    [string[]]$Files = @("docs/ai-records/background-delivery-plan.md","docs/ai-records/ui-transition-plan.md"),
    [string]$Token = $env:NOTION_TOKEN,
    [string]$ParentId = $env:NOTION_PARENT_PAGE_ID
)

if (-not $Token) {
    Write-Error "NOTION_TOKEN is not set. Set environment variable or pass -Token parameter."
    exit 1
}
if (-not $ParentId) {
    Write-Error "NOTION_PARENT_PAGE_ID is not set. Set environment variable or pass -ParentId parameter."
    exit 1
}

function Convert-MarkdownToNotionBlocks {
    param([string]$Content)
    $lines = $Content -split "\r?\n"
    $blocks = @()
    foreach ($line in $lines) {
        if ($line -match '^#\s+(.*)') {
            $text = $matches[1].Trim()
            $blocks += @{ type = 'heading_1'; heading_1 = @{ rich_text = @( @{ type = 'text'; text = @{ content = $text } } ) } }
            continue
        }
        if ($line -match '^##\s+(.*)') {
            $text = $matches[1].Trim()
            $blocks += @{ type = 'heading_2'; heading_2 = @{ rich_text = @( @{ type = 'text'; text = @{ content = $text } } ) } }
            continue
        }
        if ($line -match '^###\s+(.*)') {
            $text = $matches[1].Trim()
            $blocks += @{ type = 'heading_3'; heading_3 = @{ rich_text = @( @{ type = 'text'; text = @{ content = $text } } ) } }
            continue
        }
        if ($line.Trim() -eq '') {
            # keep a blank paragraph to preserve spacing
            $blocks += @{ type = 'paragraph'; paragraph = @{ rich_text = @() } }
            continue
        }
        # fallback: paragraph
        $blocks += @{ type = 'paragraph'; paragraph = @{ rich_text = @( @{ type = 'text'; text = @{ content = $line } } ) } }
    }
    return $blocks
}

foreach ($file in $Files) {
    if (-not (Test-Path $file)) {
        Write-Warning "File not found: $file - skipping"
        continue
    }
    Write-Host "Processing $file ..."
    $content = Get-Content $file -Raw
    $title = [System.IO.Path]::GetFileNameWithoutExtension($file) -replace '-', ' '

    $children = Convert-MarkdownToNotionBlocks -Content $content

    $body = @{
        parent = @{ page_id = $ParentId }
        properties = @{ title = @{ title = @(@{ type='text'; text = @{ content = $title } }) } }
        children = $children
    }

    $json = $body | ConvertTo-Json -Depth 10

    try {
        $resp = Invoke-RestMethod -Uri 'https://api.notion.com/v1/pages' -Method Post -Headers @{
            'Authorization' = "Bearer $Token"
            'Notion-Version' = '2022-06-28'
            'Content-Type' = 'application/json'
        } -Body $json
        Write-Host "Created page for $file -> id: $($resp.id)"
    } catch {
        Write-Error "Failed to create page for $file : $($_.Exception.Message)"
    }
}
