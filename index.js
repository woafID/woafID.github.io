function downloadFile(url, element) {
  fetch(url)
    .then(response => response.blob())
    .then(blob => {
      const link = document.createElement('a');
      link.href = URL.createObjectURL(blob);
      
      const filename = element.getAttribute('filename');
      
      link.download = filename;
      link.click();
    });
}
