const modal = document.getElementById("modal")
const modalImg = document.getElementById("modalImg")
const modalTitle = document.getElementById("modalTitle")
const modalDesc = document.getElementById("modalDesc")

function openModal(img, title, desc) {
    modal.classList.add("active")
    modalImg.src = img
    modalTitle.innerText = title
    modalDesc.innerText = desc
}

function closeModal() {
    modal.classList.remove("active")
}