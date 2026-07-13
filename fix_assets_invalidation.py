import re

with open('lib/pages/hr/admin_assets_screen.dart', 'r') as f:
    content = f.read()

# Add ref.invalidate(assetsProvider); to the create/update actions
content = content.replace(
    "await AdminOperationsRepository().createAsset(",
    "await AdminOperationsRepository().createAsset("
)
# Actually, I need to find the try blocks and insert ref.invalidate(assetsProvider); before Navigator.pop or fetch()
# Let's see if there is a _fetchData() or ref.invalidate() already.
