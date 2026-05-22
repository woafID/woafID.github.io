function downloadFile(url, element) {
  const filename = element.getAttribute('filename');

  showNotification(filename);

  setTimeout(() => {
    fetch(url)
      .then(response => response.blob())
      .then(blob => {
        const link = document.createElement('a');
        link.href = URL.createObjectURL(blob);
        link.download = filename;
        link.click();
      });
  }, 5000);
}

function showNotification(filename) {
  const modal = document.getElementById('download-modal');
  const filenameSpans = document.querySelectorAll('.filename-placeholder');

  filenameSpans.forEach(span => span.textContent = filename);

  modal.classList.add('active');
}

function closeNotification() {
  const modal = document.getElementById('download-modal');
  modal.classList.remove('active');
}
