const path = require('path');
const { CleanWebpackPlugin } = require('clean-webpack-plugin');
const fs = require('fs');

// Function to extract the Tampermonkey header from the entry file
const extractTampermonkeyHeader = () => {
    const entryFile = path.resolve(__dirname, '../src/index.js');
    const content = fs.readFileSync(entryFile, 'utf8');
    const headerMatch = content.match(/\/\*\*[\s\S]*?\*\//);
    return headerMatch ? headerMatch[0] : '';
};

module.exports = {
    mode: 'production',
    entry: './src/index.js',
    output: {
        path: path.resolve(__dirname, '../dist'),
        filename: 'telegram-media-downloader.user.js'
    },
    module: {
        rules: [
            {
                test: /\.js$/,
                exclude: /node_modules/,
                use: {
                    loader: 'babel-loader',
                    options: {
                        presets: ['@babel/preset-env']
                    }
                }
            }
        ]
    },
    plugins: [
        new CleanWebpackPlugin(),
        {
            // Custom plugin to prepend Tampermonkey header to the output bundle
            apply: (compiler) => {
                compiler.hooks.emit.tapAsync('TampermonkeyHeaderPlugin', (compilation, callback) => {
                    const header = extractTampermonkeyHeader();

                    for (const filename in compilation.assets) {
                        if (filename.endsWith('.js')) {
                            const asset = compilation.assets[filename];
                            const source = asset.source();

                            compilation.assets[filename] = {
                                source: () => `${header}\n\n${source}`,
                                size: () => asset.size() + header.length + 2
                            };
                        }
                    }

                    callback();
                });
            }
        }
    ]
};