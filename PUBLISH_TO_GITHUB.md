# Publish this sanitized archive to GitHub

Use a new empty GitHub repository. Do not reuse the old repository history or push the old `legacy-v1` tag, because the original history may still contain credentials.

## Recommended: Git-ready archive

The Git-ready package already contains a fresh local Git history with a `main` branch and the tag `legacy-v1-sanitized`. After extracting it:

```bat
cd /d D:\path\to\nabaa-artifact-repo
git status
git remote add origin https://github.com/YOUR_USERNAME/YOUR_NEW_REPOSITORY.git
git push -u origin main
git push origin legacy-v1-sanitized
```

## If using the source-only archive

The source-only package does not contain `.git`. After extracting it:

```bat
cd /d D:\path\to\nabaa-artifact-repo
git init
git branch -M main
git add .
git commit -m "chore: publish sanitized early project archive"
git tag legacy-v1-sanitized
git remote add origin https://github.com/YOUR_USERNAME/YOUR_NEW_REPOSITORY.git
git push -u origin main
git push origin legacy-v1-sanitized
```

## Web upload note

Uploading the source-only ZIP through GitHub's web page stores the ZIP as one file; GitHub will not display the README, apps, or screenshot galleries on the repository page. To make the repository browsable, extract the source-only ZIP and upload its contents, including the root `README.md`, `apps/`, `docs/`, `SECURITY.md`, and `.gitignore`. The Git-ready ZIP is not useful as a web-uploaded ZIP because its `.git` folder is treated as ordinary archived data.

## Final local check

Before pushing, run:

```bat
git grep -n -I -E "AIza[0-9A-Za-z_-]{20,}|-----BEGIN (RSA|OPENSSH|EC) PRIVATE KEY-----|cloudfunctions\.net|googleusercontent\.com" -- ":!PUBLISH_TO_GITHUB.md"
```

The command should return no matches. Enable GitHub secret scanning and push protection on the new repository. Keep the original repositories private until their history has been checked and any exposed credentials have been revoked.
