import os
import re

toast_map = {
    r"'Saved'": "AppToastMessages.saved",
    r"'Deleted'": "AppToastMessages.deleted",
    r"'Restored'": "AppToastMessages.restored",
    r"'Save failed'": "AppToastMessages.error",
    r"'Error'": "AppToastMessages.error",
    r"'Login required'": "AppToastMessages.loginRequired",
    r'"Scanned"': "AppToastMessages.scanned",
    r'"Scanning..."': "AppToastMessages.scanning",
    r'"Please enable SMS scanner in settings to use this feature"': "AppToastMessages.enableSmsScanner",
    r"'Permission Required'": "AppToastMessages.permissionRequired",
    r"'Permission Denied'": "AppToastMessages.permissionDenied",
    r"'Data restored successfully!'": "AppToastMessages.restoreSuccess",
    r"'Split exceeds total'": "AppToastMessages.splitExceedsTotal",
    r"'Profile updated successfully'": "AppToastMessages.profileUpdated",
    r"'Profile photo removed'": "AppToastMessages.profilePhotoRemoved",
    r"'Please enter your name'": "AppToastMessages.nameRequired",
    r"'Downloaded successfully'": "AppToastMessages.downloaded",
    r"'Download failed.'": "AppToastMessages.downloadFailed",
    r"'Please enter a file name'": "AppToastMessages.fileNameRequired",
    r"'Authentication failed'": "AppToastMessages.authFailed",
}

dynamic_toast_map = {
    r"'Failed to share app: \$e'": "AppToastMessages.shareFailed + ': $e'",
    r"'Failed to restore data: \$e'": "AppToastMessages.restoreFailed + ': $e'",
    r"'Failed to update profile: \$e'": "AppToastMessages.profileUpdateFailed + ': $e'",
    r"'Failed to remove photo'": "AppToastMessages.profilePhotoRemoveFailed",
    r"'Export failed: \$e'": "AppToastMessages.exportFailed + ': $e'",
    r"'Failed to save: \$e'": "AppToastMessages.saveFailed + ': $e'",
}

def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    original_content = content
    
    if 'AppToast.show(' in content:
        for old, new in toast_map.items():
            content = content.replace(old, new)
        for old, new in dynamic_toast_map.items():
            content = re.sub(old, new, content)
            
        if content != original_content:
            # add import if not present
            if 'import \'package:smart_money_tracker/core/constants/app_toast_messages.dart\';' not in content:
                # Find the last import line
                lines = content.split('\n')
                last_import_idx = -1
                for i, line in enumerate(lines):
                    if line.startswith('import '):
                        last_import_idx = i
                
                if last_import_idx != -1:
                    lines.insert(last_import_idx + 1, "import 'package:smart_money_tracker/core/constants/app_toast_messages.dart';")
                    content = '\n'.join(lines)
            
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(content)
            print(f"Updated {filepath}")

for root, dirs, files in os.walk('lib'):
    for file in files:
        if file.endswith('.dart'):
            process_file(os.path.join(root, file))
