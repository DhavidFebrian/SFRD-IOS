@echo off
echo ==========================================
echo   Pushing SFRD iOS to GitHub Repository
echo ==========================================
git add .
git commit -m "Update SFRD iOS source and CI/CD"
git branch -M main
git push -u origin main
echo ==========================================
echo   Done! Periksa GitHub Actions tab untuk build .ipa
echo ==========================================
pause
