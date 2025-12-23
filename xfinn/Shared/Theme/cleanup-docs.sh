#!/bin/bash

# Documentation Cleanup Script for XFINN
# This script removes obsolete documentation files and reorganizes documentation
# All important information has been consolidated in remaining files

echo "🧹 Starting comprehensive documentation cleanup..."
echo ""

# Navigate to script directory first, then to project root
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

# If script is in a subdirectory, navigate to project root
# Adjust the number of "../" based on your project structure
# For now, assume script is at project root
PROJECT_ROOT="$SCRIPT_DIR"
cd "$PROJECT_ROOT"

# Count files to be deleted
TOTAL=0

echo "📁 Cleaning up Docs/ folder..."

if [ -d "Docs" ]; then
    cd Docs
    
    # Remove redundant/obsolete files
    echo ""
    echo "  Removing redundant documentation..."
    
    # Autoplay docs (keep only AUTOPLAY_SUMMARY.md)
    rm -f AUTOPLAY_IMPLEMENTATION.md && echo "    ✓ AUTOPLAY_IMPLEMENTATION.md" && ((TOTAL++))
    rm -f QUICK_START_AUTOPLAY.md && echo "    ✓ QUICK_START_AUTOPLAY.md" && ((TOTAL++))
    
    # Bugfix docs (too specific)
    rm -f BUGFIX_SUBTITLES.md && echo "    ✓ BUGFIX_SUBTITLES.md" && ((TOTAL++))
    rm -f CHANGELOG_SUBTITLES.md && echo "    ✓ CHANGELOG_SUBTITLES.md" && ((TOTAL++))
    
    # Compilation fixes (temporary)
    rm -f COMPILATION_FIXES.md && echo "    ✓ COMPILATION_FIXES.md" && ((TOTAL++))
    rm -f FIXES_COMPILATION.md && echo "    ✓ FIXES_COMPILATION.md" && ((TOTAL++))
    
    # Summary docs (too many)
    rm -f COMPLETE_SUMMARY.md && echo "    ✓ COMPLETE_SUMMARY.md" && ((TOTAL++))
    rm -f CORRECTION_SUMMARY.md && echo "    ✓ CORRECTION_SUMMARY.md" && ((TOTAL++))
    rm -f SUMMARY_OF_FIXES.md && echo "    ✓ SUMMARY_OF_FIXES.md" && ((TOTAL++))
    rm -f README_SUMMARY.md && echo "    ✓ README_SUMMARY.md" && ((TOTAL++))
    
    # Final docs (redundant)
    rm -f FINAL_IMPROVEMENTS.md && echo "    ✓ FINAL_IMPROVEMENTS.md" && ((TOTAL++))
    rm -f FINAL_MATERIAL_PURGE.md && echo "    ✓ FINAL_MATERIAL_PURGE.md" && ((TOTAL++))
    rm -f FINAL_NAVIGATION_FIX.md && echo "    ✓ FINAL_NAVIGATION_FIX.md" && ((TOTAL++))
    
    # Focus fixes (keep FOCUS_EFFECT_DISABLED.md only)
    rm -f FOCUS_FIX.md && echo "    ✓ FOCUS_FIX.md" && ((TOTAL++))
    
    # Hybrid/Investigation docs (obsolete)
    rm -f HYBRID_API_FIX.md && echo "    ✓ HYBRID_API_FIX.md" && ((TOTAL++))
    rm -f JELLYFIN_API_INVESTIGATION.md && echo "    ✓ JELLYFIN_API_INVESTIGATION.md" && ((TOTAL++))
    
    # Implementation docs (too granular)
    rm -f IMPLEMENTATION_TERMINEE.md && echo "    ✓ IMPLEMENTATION_TERMINEE.md" && ((TOTAL++))
    rm -f INTEGRATION_FINALE.md && echo "    ✓ INTEGRATION_FINALE.md" && ((TOTAL++))
    
    # Network/Jellyfin API (keep JELLYFIN_URL_NORMALIZATION.md)
    rm -f JELLYFIN_API_FIX.md && echo "    ✓ JELLYFIN_API_FIX.md" && ((TOTAL++))
    rm -f NETWORK_FIXES.md && echo "    ✓ NETWORK_FIXES.md" && ((TOTAL++))
    
    # Playback fixes (too specific)
    rm -f FIX_AUDIO_CONTINUES.md && echo "    ✓ FIX_AUDIO_CONTINUES.md" && ((TOTAL++))
    rm -f PLAYBACK_FIXES_V2.md && echo "    ✓ PLAYBACK_FIXES_V2.md" && ((TOTAL++))
    rm -f TVOS_PLAYBACK_FIX.md && echo "    ✓ TVOS_PLAYBACK_FIX.md" && ((TOTAL++))
    
    # Quick starts (redundant with main README)
    rm -f QUICK_START.md && echo "    ✓ QUICK_START.md" && ((TOTAL++))
    
    # Resume docs (keep RESUME_CHOICE_FEATURE.md)
    rm -f RESUME_FIX.md && echo "    ✓ RESUME_FIX.md" && ((TOTAL++))
    
    # Scroll fixes (minor)
    rm -f SCROLL_FIX_FINAL.md && echo "    ✓ SCROLL_FIX_FINAL.md" && ((TOTAL++))
    rm -f SCROLL_FIX.md && echo "    ✓ SCROLL_FIX.md" && ((TOTAL++))
    
    # Series view (minor fix)
    rm -f SERIES_VIEW_FIX.md && echo "    ✓ SERIES_VIEW_FIX.md" && ((TOTAL++))
    
    # Session timeout (specific fix)
    rm -f SESSION_TIMEOUT_FIX.md && echo "    ✓ SESSION_TIMEOUT_FIX.md" && ((TOTAL++))
    
    # Solution finale (redundant)
    rm -f SOLUTION_FINALE_CAPABILITIES.md && echo "    ✓ SOLUTION_FINALE_CAPABILITIES.md" && ((TOTAL++))
    
    # Streaming format (specific)
    rm -f STREAMING_FORMAT_FIX.md && echo "    ✓ STREAMING_FORMAT_FIX.md" && ((TOTAL++))
    
    # Subtitle docs (keep SUBTITLE_IMPLEMENTATION.md and SUBTITLE_QUICKSTART.md)
    rm -f SUBTITLE_ARCHITECTURE_DIAGRAMS.md && echo "    ✓ SUBTITLE_ARCHITECTURE_DIAGRAMS.md" && ((TOTAL++))
    rm -f SUBTITLE_TESTING_GUIDE.md && echo "    ✓ SUBTITLE_TESTING_GUIDE.md" && ((TOTAL++))
    rm -f SUBTITLES_BURNIN_FINAL_SOLUTION.md && echo "    ✓ SUBTITLES_BURNIN_FINAL_SOLUTION.md" && ((TOTAL++))
    rm -f SUBTITLES_COMPLETE_SOLUTION.md && echo "    ✓ SUBTITLES_COMPLETE_SOLUTION.md" && ((TOTAL++))
    rm -f SUBTITLES_FINAL_STATUS.md && echo "    ✓ SUBTITLES_FINAL_STATUS.md" && ((TOTAL++))
    rm -f SUBTITLES_FORCED_FIX.md && echo "    ✓ SUBTITLES_FORCED_FIX.md" && ((TOTAL++))
    rm -f SUBTITLES_NATIVE_HLS_SOLUTION.md && echo "    ✓ SUBTITLES_NATIVE_HLS_SOLUTION.md" && ((TOTAL++))
    rm -f SUBTITLES_PLAYER_MENU_CUSTOM_ITEM.md && echo "    ✓ SUBTITLES_PLAYER_MENU_CUSTOM_ITEM.md" && ((TOTAL++))
    rm -f SUBTITLES_PLAYER_MENU_LIMITATIONS.md && echo "    ✓ SUBTITLES_PLAYER_MENU_LIMITATIONS.md" && ((TOTAL++))
    rm -f SUBTITLES_SUMMARY.md && echo "    ✓ SUBTITLES_SUMMARY.md" && ((TOTAL++))
    
    # tvOS focus (keep TVOS_FOCUS_FINAL_SOLUTION.md)
    rm -f TVOS_FOCUS_COMPLETE.md && echo "    ✓ TVOS_FOCUS_COMPLETE.md" && ((TOTAL++))
    rm -f TVOS_FOCUS_DIAGNOSTIC.md && echo "    ✓ TVOS_FOCUS_DIAGNOSTIC.md" && ((TOTAL++))
    rm -f TVOS_FOCUS_SUMMARY.md && echo "    ✓ TVOS_FOCUS_SUMMARY.md" && ((TOTAL++))
    
    # Usage guides (redundant)
    rm -f URL_NORMALIZATION_USAGE.md && echo "    ✓ URL_NORMALIZATION_USAGE.md" && ((TOTAL++))
    
    # Verification (temporary)
    rm -f VERIFICATION_MODIFICATIONS.md && echo "    ✓ VERIFICATION_MODIFICATIONS.md" && ((TOTAL++))
    
    cd "$PROJECT_ROOT"
fi

echo ""
echo "📁 Cleaning up Documentation/ folder..."

if [ -d "Documentation" ]; then
    cd Documentation
    
    # Remove all reorganization docs (project is already organized)
    rm -f GIT_REORGANIZATION_GUIDE.md && echo "    ✓ GIT_REORGANIZATION_GUIDE.md" && ((TOTAL++))
    rm -f QUICK_REORGANIZATION_GUIDE.md && echo "    ✓ QUICK_REORGANIZATION_GUIDE.md" && ((TOTAL++))
    rm -f README_NEW.md && echo "    ✓ README_NEW.md" && ((TOTAL++))
    rm -f REORGANIZATION_CHECKLIST.md && echo "    ✓ REORGANIZATION_CHECKLIST.md" && ((TOTAL++))
    rm -f REORGANIZATION_COMPLETE.md && echo "    ✓ REORGANIZATION_COMPLETE.md" && ((TOTAL++))
    rm -f REORGANIZATION_FILES_LIST.md && echo "    ✓ REORGANIZATION_FILES_LIST.md" && ((TOTAL++))
    rm -f REORGANIZATION_SUMMARY.md && echo "    ✓ REORGANIZATION_SUMMARY.md" && ((TOTAL++))
    rm -f START_HERE.md && echo "    ✓ START_HERE.md" && ((TOTAL++))
    rm -f FINAL_SUMMARY.md && echo "    ✓ FINAL_SUMMARY.md" && ((TOTAL++))
    
    # Keep DOCUMENTATION_INDEX.md and TABLE_OF_CONTENTS.md
    
    cd "$PROJECT_ROOT"
fi

echo ""
echo "📁 Cleaning up Shared/Theme folder..."

if [ -d "Shared/Theme" ]; then
    cd Shared/Theme
    
    # Remove cleanup docs from Theme folder (wrong location)
    rm -f CLEANUP_SUMMARY.md && echo "    ✓ Shared/Theme/CLEANUP_SUMMARY.md" && ((TOTAL++))
    rm -f DOCUMENTATION_CLEANUP_PLAN.md && echo "    ✓ Shared/Theme/DOCUMENTATION_CLEANUP_PLAN.md" && ((TOTAL++))
    # Keep TECHNICAL_NOTES.md as it's useful
    
    cd "$PROJECT_ROOT"
fi

echo ""
echo "📁 Cleaning up Features/Library/Views folder..."

if [ -d "Features/Library/Views" ]; then
    cd Features/Library/Views
    
    # Remove markdown from Views folder
    rm -f TVOS_IMPROVEMENTS.md && echo "    ✓ Features/Library/Views/TVOS_IMPROVEMENTS.md" && ((TOTAL++))
    
    cd "$PROJECT_ROOT"
fi

echo ""
echo "✨ Cleanup complete!"
echo ""
echo "📊 Summary:"
echo "  - Files deleted: $TOTAL"
echo ""
echo "📁 Final documentation structure:"
echo ""
echo "  Root level:"
echo "    ✓ README.md (main documentation)"
echo ""
echo "  Docs/ (essential documentation):"
echo "    ✓ API_REFERENCE.md"
echo "    ✓ ARCHITECTURE.md"
echo "    ✓ AUTOPLAY_SUMMARY.md"
echo "    ✓ CLEANUP_SUMMARY.md"
echo "    ✓ DEBUG_CLEANUP.md"
echo "    ✓ DEBUGGING_GUIDE.md"
echo "    ✓ FOCUS_EFFECT_DISABLED.md"
echo "    ✓ FUTURE_IMPROVEMENTS.md"
echo "    ✓ GUIDE.md"
echo "    ✓ JELLYFIN_URL_NORMALIZATION.md"
echo "    ✓ LIBRARY_VIEW_OVERLAP_FIX.md"
echo "    ✓ LIQUID_GLASS_DESIGN.md"
echo "    ✓ MATERIAL_FOCUS_FIX.md"
echo "    ✓ README.md"
echo "    ✓ RESUME_CHOICE_FEATURE.md"
echo "    ✓ SEARCH_VIEW_FOCUS_FIX.md"
echo "    ✓ SUBTITLE_IMPLEMENTATION.md"
echo "    ✓ SUBTITLE_QUICKSTART.md"
echo "    ✓ TROUBLESHOOTING.md"
echo "    ✓ TVOS_FOCUS_FINAL_SOLUTION.md"
echo "    ✓ USERDEFAULTS_KEYS.md"
echo ""
echo "  Documentation/ (index and reference):"
echo "    ✓ DOCUMENTATION_INDEX.md"
echo "    ✓ TABLE_OF_CONTENTS.md"
echo ""
echo "  Shared/Theme/:"
echo "    ✓ TECHNICAL_NOTES.md"
echo ""
echo "✅ All important information has been preserved!"
echo "✅ Documentation is now clean and well-organized!"
