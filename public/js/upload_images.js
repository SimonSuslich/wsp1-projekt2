let fileArray = []; // Array to store selected files

function previewImages(event) {
    const files = Array.from(event.target.files); // Convert FileList to array
    const previewContainer = document.getElementById('imagePreviewContainer');

    // Add files to the custom fileArray
    fileArray.push(...files);

    // Display each file in the preview container
    files.forEach(file => {
        const reader = new FileReader();

        // Create a preview element
        const previewDiv = document.createElement('div');
        previewDiv.classList.add('image-preview');
        const img = document.createElement('img');
        const deleteButton = document.createElement('button');
        deleteButton.textContent = 'X';
        deleteButton.onclick = () => {
            // Remove file from fileArray and preview
            fileArray = fileArray.filter(f => f !== file);
            previewDiv.remove();
        };

        previewDiv.appendChild(img);
        previewDiv.appendChild(deleteButton);
        previewContainer.appendChild(previewDiv);

        reader.onload = function (e) {
            img.src = e.target.result;
        };
        reader.readAsDataURL(file);
    });

    event.target.value = ''; // Clear the file input so it doesn't interfere with adding new files
}

function removeAllImages() {
    const previewContainer = document.getElementById('imagePreviewContainer');
    previewContainer.innerHTML = ''; // Clear the preview container
    fileArray = []; // Clear the file array
}

function prepareFiles(event) {
    event.preventDefault(); // Prevent default form submission

    const form = event.target;
    const formData = new FormData(form);

    // Add custom file array to the FormData object
    fileArray.forEach(file => formData.append('imagesArray[]', file));

    // Submit the form data using fetch
    fetch(form.action, {
        method: form.method,
        body: formData,
    })
    .then(response => {
        if (response.ok) {
            console.log('Form submitted successfully!');
        } else {
            console.error('Form submission failed.');
        }
    })
    .catch(error => {
        console.error('Error during submission:', error);
    });
}