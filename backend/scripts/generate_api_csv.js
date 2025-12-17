const fs = require('fs');
const path = require('path');

const postmanPath = path.join(__dirname, '../Unified_Trevel_API.postman_collection.json');
const outputPath = path.join(__dirname, '../API_Test_Plan.csv');

try {
    const rawData = fs.readFileSync(postmanPath, 'utf8');
    const collection = JSON.parse(rawData);

    let csvContent = 'Module,API Name,Method,Endpoint,Description,Status (Dropdown Placeholder)\n';

    function traverseItems(items, folderName = '') {
        items.forEach(item => {
            if (item.item) {
                // It's a folder
                const newFolderName = folderName ? `${folderName} > ${item.name}` : item.name;
                traverseItems(item.item, newFolderName);
            } else if (item.request) {
                // It's a request
                const module = folderName || 'Root';
                const name = item.name.replace(/,/g, ' '); // simple escape for CSV
                const method = item.request.method;

                let url = '';
                if (typeof item.request.url === 'string') {
                    url = item.request.url;
                } else if (item.request.url && item.request.url.raw) {
                    url = item.request.url.raw;
                }

                // Clean URL variable syntax if needed, or leave as is
                url = url.replace(/,/g, '');

                const description = (item.request.description || '').replace(/\n/g, ' ').replace(/,/g, ' ');

                csvContent += `"${module}","${name}","${method}","${url}","${description}","Pending"\n`;
            }
        });
    }

    traverseItems(collection.item);

    fs.writeFileSync(outputPath, csvContent);
    console.log(`Successfully generated CSV at ${outputPath}`);

} catch (error) {
    console.error('Error generating CSV:', error);
    process.exit(1);
}
