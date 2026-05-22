// Handle filter button
const filterBtn = document.querySelector('.filter-btn');

filterBtn.addEventListener('click', function() {
    console.log('Filter applied');
    // Bisa menambahkan logic untuk filter data
});

// Handle action buttons (Edit)
const editBtns = document.querySelectorAll('.edit-btn');
editBtns.forEach(btn => {
    btn.addEventListener('click', function(e) {
        e.stopPropagation();
        const rentalName = this.closest('tr').querySelector('.rental-name span').textContent;
        console.log('Edit rental:', rentalName);
        alert('Edit: ' + rentalName);
    });
});

// Handle action buttons (Delete)
const deleteBtns = document.querySelectorAll('.delete-btn');
deleteBtns.forEach(btn => {
    btn.addEventListener('click', function(e) {
        e.stopPropagation();
        const rentalName = this.closest('tr').querySelector('.rental-name span').textContent;
        if (confirm('Apakah Anda yakin ingin menghapus ' + rentalName + '?')) {
            console.log('Delete rental:', rentalName);
            // Bisa menambahkan logic untuk delete dari API
        }
    });
});

// Handle pagination
const paginationBtns = document.querySelectorAll('.pagination-btn:not(.prev-btn):not(.next-btn)');
const prevBtn = document.querySelector('.pagination-btn.prev-btn');
const nextBtn = document.querySelector('.pagination-btn.next-btn');

paginationBtns.forEach(btn => {
    btn.addEventListener('click', function() {
        if (this.textContent !== '...') {
            paginationBtns.forEach(b => b.classList.remove('active'));
            this.classList.add('active');
            
            console.log('Go to page:', this.textContent);
            // Update enablement of prev/next buttons
            const currentPage = parseInt(this.textContent);
            prevBtn.disabled = currentPage === 1;
            nextBtn.disabled = currentPage === 7; // Assuming 7 pages
        }
    });
});

nextBtn.addEventListener('click', function() {
    const currentActive = document.querySelector('.pagination-btn.active');
    const currentPage = parseInt(currentActive.textContent);
    if (currentPage < 7) {
        const nextPage = document.querySelector(`.pagination-btn:nth-child(${currentPage + 2})`);
        if (nextPage) {
            nextPage.click();
        }
    }
});

prevBtn.addEventListener('click', function() {
    const currentActive = document.querySelector('.pagination-btn.active');
    const currentPage = parseInt(currentActive.textContent);
    if (currentPage > 1) {
        const prevPage = document.querySelector(`.pagination-btn:nth-child(${currentPage})`);
        if (prevPage) {
            prevPage.click();
        }
    }
});

// Handle sidebar navigation
const navItems = document.querySelectorAll('.nav-item');
navItems.forEach(item => {
    item.addEventListener('click', function() {
        const page = this.querySelector('span').textContent;
        
        navItems.forEach(nav => nav.classList.remove('active'));
        this.classList.add('active');
        
        if (page === 'Dashboard') {
            window.location.href = 'dashboard.html';
        } else if (page === 'Komisi') {
            window.location.href = 'komisi.html';
        } else if (page === 'Pemilih Rental') {
            window.location.href = 'pemilik-rental.html';
        } else if (page === 'Transaksi') {
            window.location.href = 'transaksi.html';
        } else if (page === 'System Settings') {
            window.location.href = 'settings.html';
        }
    });
});

// Handle user profile click
const userProfile = document.querySelector('.user-profile');
userProfile.addEventListener('click', function() {
    console.log('Show user profile menu');
    // Bisa menampilkan menu dropdown untuk user settings
});

// Initialize
document.addEventListener('DOMContentLoaded', function() {
    console.log('Pemilik Rental page loaded');
    // Bisa menambahkan inisialisasi data dari API
});
