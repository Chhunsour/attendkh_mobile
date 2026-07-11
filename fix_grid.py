import re

with open('lib/pages/hr/admin_assets_screen.dart', 'r') as f:
    content = f.read()

# Replace GridView with ListView for mobile
pattern_grid = r"                          return GridView\.builder\([\s\S]*?                          \);"
new_list = """                          if (crossAxisCount == 1) {
                            return ListView.separated(
                              padding: const EdgeInsets.all(14),
                              itemCount: items.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 10),
                              itemBuilder: (context, i) => _buildAssetCard(items[i]),
                            );
                          }
                          return GridView.builder(
                            padding: const EdgeInsets.all(14),
                            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 400,
                              mainAxisSpacing: 10,
                              crossAxisSpacing: 10,
                              mainAxisExtent: 240,
                            ),
                            itemCount: items.length,
                            itemBuilder: (context, i) => _buildAssetCard(items[i]),
                          );"""

content = re.sub(pattern_grid, new_list, content)

# Remove Spacer() in _buildAssetCard
pattern_spacer = r"              const Spacer\(\),\n              _actionButton\(Icons\.history"
new_spacer = r"              const SizedBox(height: 16),\n              _actionButton(Icons.history"
content = re.sub(pattern_spacer, new_spacer, content)

with open('lib/pages/hr/admin_assets_screen.dart', 'w') as f:
    f.write(content)
print("done")
