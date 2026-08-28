<#
.SYNOPSIS
  Scaffolds a new topic folder from templates/, so a new seminar paper starts with the
  shared process already wired up and only its subject matter left to fill in.

.DESCRIPTION
  Creates the folder, the directory skeleton the teach skill expects, and a copy of every
  file in templates/ under its real name. Nothing subject-specific is invented: the
  templates carry placeholders you fill in during the first session.

  What it deliberately does NOT create:
    * assets/  - shared, lives at the course level; lessons link ../../assets/...
    * ieee.csl, the generic tools - shared, run them as ..\tools\<script>.ps1
    * mysql-credentials.cnf - holds a password, so you write it yourself

  Run from anywhere. Safe to re-run: it refuses to overwrite an existing folder.

.EXAMPLE
  .\tools\new-topic.ps1 -Name "Tema 2. - Transakcije i konkurentnost" -Slug transakcije
#>
param(
    [Parameter(Mandatory)] [string]$Name,
    [Parameter(Mandatory)] [string]$Slug
)

$ErrorActionPreference = 'Stop'
$course = Split-Path -Parent $PSScriptRoot
$topic = Join-Path $course $Name

if (Test-Path $topic) { throw "'$topic' already exists - pick another name, or delete it first." }
$templates = Join-Path $course 'templates'
if (-not (Test-Path $templates)) { throw "templates/ not found at $templates" }

New-Item -ItemType Directory -Path $topic | Out-Null
foreach ($d in 'lessons', 'reference', 'learning-records', 'examples', 'figures', 'figures/raw',
                'tools', ".scratch/$Slug/issues", ".scratch/$Slug/research", ".scratch/$Slug/measurements") {
    New-Item -ItemType Directory -Force -Path (Join-Path $topic $d) | Out-Null
}

# templates/<name> -> topic/<real name>. Most map straight across; four are renamed.
$map = @{
    'MISSION.md'                 = 'MISSION.md'
    'NOTES.md'                   = 'NOTES.md'
    'RESOURCES.md'               = 'RESOURCES.md'
    'rad.md'                     = 'rad.md'
    'naslovna.md'                = 'naslovna.md'
    'gitignore'                  = '.gitignore'
    'learning-records-README.md' = 'learning-records/README.md'
    'figures-README.md'          = 'figures/README.md'
}
# UTF-8 without a BOM, both directions. PowerShell 5.1 gets this wrong twice by default:
# Get-Content reads a BOM-less UTF-8 file as ANSI (mangling every accented character), and
# Out-File -Encoding utf8 writes a BOM that leaks into the first heading.
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
function Write-Template([string]$Text, [string]$Path) {
    [System.IO.File]::WriteAllText($Path, $Text, $utf8NoBom)
}

foreach ($k in $map.Keys) {
    $src = Join-Path $templates $k
    if (-not (Test-Path $src)) { throw "template '$k' missing from $templates" }
    $dst = Join-Path $topic $map[$k]
    $text = [System.IO.File]::ReadAllText($src, [System.Text.Encoding]::UTF8)
    Write-Template $text.Replace('{Topic}', $Name).Replace('<topic>', $Slug) $dst
}

# A glossary is written during the first session, not scaffolded: its whole point is that the
# terminology is decided once, deliberately, before any chapter is written.
$glossary = @"
# Glossary and skeleton - binding on every chapter

Terminology and chapter skeleton for **$Name**. Written in the first session, before any chapter,
so a term is decided once and never re-translated later. Do not deviate from a term below without
updating this file first and noting why.

**How to read it cheaply:** the term tables are always relevant; each chapter-specific subsection is
read only when working on that chapter. The reasoning behind a locked non-choice belongs in
``.scratch/$Slug/terminology-rationale.md``; the one-line rule here is the binding part.

Voice and citation density are **not** here - they are the same for every paper in this course and
live in ``../WRITING.md``.

## 1. Terminology

| Concept | Serbian term (first use) | After first use |
|---|---|---|
|  |  |  |

## 2. Chapter skeleton - top-level

| # | Chapter | Page budget |
|---|---|---|
| 1 | Uvod |  |
"@
Write-Template $glossary (Join-Path $topic 'GLOSSARY.md')
Write-Template '' (Join-Path $topic 'references.bib')

Write-Host ""
Write-Host "Created $topic" -ForegroundColor Green
Write-Host ""
Write-Host "Next:" -ForegroundColor Cyan
Write-Host "  1. cd `"$topic`""
Write-Host "  2. Fill in MISSION.md - the agent will interview you if you start without it."
Write-Host "  3. Set the title in naslovna.md and rad.md."
Write-Host "  4. Add mysql-credentials.cnf if this topic needs a live server (gitignored)."
Write-Host "  5. claude, then /teach <first topic>."
Write-Host ""
