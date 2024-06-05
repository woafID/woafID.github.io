function downloadFile() {
    const url = 'https://raw.githubusercontent.com/woafID/psychic-engine/main/Affinity_Linux.sh';
    const filename = 'Affinity_Linux.sh';
  
    fetch(url)
      .then(response => response.blob())
      .then(blob => {
        const link = document.createElement('a');
        link.href = URL.createObjectURL(blob);
        link.download = filename;
        link.click();
      });
  }