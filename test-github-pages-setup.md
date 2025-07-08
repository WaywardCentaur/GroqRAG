# GitHub Pages Deployment Test

## Quick Test Steps:

1. **Push this workflow to main branch:**
   ```bash
   git add .github/workflows/deploy-anna-webinar-demo.yml
   git commit -m "Add GitHub Pages deployment workflow"
   git push origin main
   ```

2. **Trigger the workflow manually (if needed):**
   - Go to your repository on GitHub
   - Click "Actions" tab
   - Click "Deploy Anna Webinar Demo to GitHub Pages" workflow
   - Click "Run workflow" button
   - Select "main" branch and click "Run workflow"

3. **Monitor the deployment:**
   - Watch the workflow run in the Actions tab
   - Check each step for any errors
   - Look for the final success message

4. **Verify the deployed site:**
   - Visit: https://waywardcentaur.github.io/GroqRAG/anna-webinar-demo/
   - It may take 5-10 minutes for GitHub Pages to update

## Expected URLs:
- **Main site:** https://waywardcentaur.github.io/GroqRAG/
- **Anna Demo:** https://waywardcentaur.github.io/GroqRAG/anna-webinar-demo/

## Troubleshooting:

### If workflow fails with "git failed with exit code 128":
1. **Check Repository Settings:**
   - Go to Settings → Actions → General
   - Under "Workflow permissions", select "Read and write permissions"
   - Check "Allow GitHub Actions to create and approve pull requests"

2. **Verify GitHub Pages Configuration:**
   - Go to Settings → Pages
   - Source should be "GitHub Actions" (not "Deploy from a branch")
   - Save the settings

3. **Check Branch Protection:**
   - Ensure the `gh-pages` branch (if it exists) doesn't have protection rules blocking the action
   - Go to Settings → Branches and check protection rules

4. **Verify Checkout Step:**
   - The workflow now uses `fetch-depth: 1` for better reliability
   - Git configuration is set up automatically before deployment
   - Repository verification step checks git status

### If checkout step fails:
1. Check if the repository is accessible
2. Verify you haven't overridden repository, ref, or token settings
3. Ensure the workflow is running on the correct branch (main)

### If workflow fails:
1. Check the Actions tab for detailed error logs
2. Verify repository settings (Pages enabled, permissions set)
3. Ensure the build completes locally first

### If deployment succeeds but site doesn't load:
1. Wait 5-10 minutes for GitHub Pages cache to update
2. Check GitHub Pages settings in repository
3. Verify the `gh-pages` branch was created

### If you get 404 errors:
1. Check that GitHub Pages source is set to "GitHub Actions"
2. Verify the `destination_dir: anna-webinar-demo` is correct
3. Check that `homepage` in package.json matches the URL structure

## Current Configuration:
- ✅ Workflow file created
- ✅ Build artifacts verified locally
- ✅ Environment variables set
- ✅ Permissions configured
- ✅ Deploy path: `./anna-webinar-demo/build`
- ✅ Target URL: `/anna-webinar-demo/`
