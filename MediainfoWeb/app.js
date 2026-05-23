document.addEventListener('DOMContentLoaded', () => {
    const dropzone = document.getElementById('dropzone');
    const fileInput = document.getElementById('file-input');
    const dropzoneContent = document.querySelector('.dropzone-content');
    const loading = document.getElementById('loading');
    const outputContainer = document.getElementById('output-container');
    const outputElement = document.getElementById('output');
    const filenameElement = document.getElementById('output-filename');

    // Click to select file
    dropzone.addEventListener('click', () => {
        fileInput.click();
    });

    fileInput.addEventListener('change', (e) => {
        if (e.target.files.length) {
            handleFile(e.target.files[0]);
        }
    });

    // Drag and Drop Events
    ['dragenter', 'dragover', 'dragleave', 'drop'].forEach(eventName => {
        dropzone.addEventListener(eventName, preventDefaults, false);
        document.body.addEventListener(eventName, preventDefaults, false);
    });

    function preventDefaults(e) {
        e.preventDefault();
        e.stopPropagation();
    }

    ['dragenter', 'dragover'].forEach(eventName => {
        dropzone.addEventListener(eventName, () => {
            dropzone.classList.add('dragover');
        }, false);
    });

    ['dragleave', 'drop'].forEach(eventName => {
        dropzone.addEventListener(eventName, () => {
            dropzone.classList.remove('dragover');
        }, false);
    });

    dropzone.addEventListener('drop', (e) => {
        const dt = e.dataTransfer;
        const files = dt.files;

        if (files.length) {
            handleFile(files[0]);
        }
    }, false);

    const makeReadChunk = (file) => async (chunkSize, offset) => {
        return new Uint8Array(await file.slice(offset, offset + chunkSize).arrayBuffer());
    };

    function handleFile(file) {
        // Update UI
        dropzoneContent.classList.add('hidden');
        loading.classList.remove('hidden');
        outputContainer.classList.add('hidden');
        filenameElement.textContent = file.name;

        // Initialize MediaInfo WASM
        const mediainfoFactory = window.MediaInfo || window.MediaInfoLib;
        const factoryFunc = (mediainfoFactory && mediainfoFactory.mediaInfoFactory) ? mediainfoFactory.mediaInfoFactory : mediainfoFactory;
        
        factoryFunc({ format: 'text', locateFile: (path, prefix) => `lib/${path}` })
            .then(mediainfo => {
                return mediainfo.analyzeData(() => file.size, makeReadChunk(file))
                    .then(result => {
                        showOutput(result || "No output generated.");
                        mediainfo.close();
                    })
                    .catch(err => {
                        showOutput(`Analysis failed: ${err.message}`);
                        mediainfo.close();
                    });
            })
            .catch(err => {
                showOutput(`Failed to initialize mediainfo.js: ${err.message}`);
            })
            .finally(() => {
                // Reset UI
                loading.classList.add('hidden');
                dropzoneContent.classList.remove('hidden');
            });
    }

    function formatOutput(text) {
        // Escape HTML
        let escaped = text.replace(/&/g, '&amp;')
                          .replace(/</g, '&lt;')
                          .replace(/>/g, '&gt;');
        
        return escaped.split('\n').map(line => {
            // Header (e.g., General, Video, Audio)
            if (/^[A-Z][a-z]+(\s+#\d+)?$/.test(line.trim())) {
                return `<span class="hl-header">${line}</span>`;
            }
            
            // Key-Value pair
            const match = line.match(/^(.+?)\s*:\s*(.*)$/);
            if (match) {
                const [_, key, value] = match;
                return `<span class="hl-key">${key}</span><span class="hl-sep">:</span> <span class="hl-value">${value}</span>`;
            }
            
            return line;
        }).join('\n');
    }

    function showOutput(text) {
        outputElement.innerHTML = formatOutput(text);
        outputContainer.classList.remove('hidden');
    }
});
