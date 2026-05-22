// Handle filter button
const filterBtn = document.querySelector('.filter-btn');
const searchInput = document.querySelector('.search-box input');

filterBtn.addEventListener('click', function() {
    const searchValue = searchInput.value;
    const statusFilter = document.querySelectorAll('.filter-select')[0].value;
    const periodFilter = document.querySelectorAll('.filter-select')[1].value;
    
    console.log('Filter applied:', {
        search: searchValue,
        status: statusFilter,
        period: periodFilter
    });
    
    // Di sini bisa menambahkan logic untuk filter data
    // Filter data berdasarkan kriteria
    filterTableData(searchValue, statusFilter, periodFilter);
});

// Filter table data
function filterTableData(search, status, period) {
    const tableRows = document.querySelectorAll('.transactions-table tbody tr');
    
    tableRows.forEach(row => {
        let shouldShow = true;
        
        // Filter berdasarkan search
        if (search) {
            const transactionId = row.querySelector('.transaction-id').textContent.toLowerCase();
            const userName = row.querySelector('.user-name').textContent.toLowerCase();
            const rentalItem = row.querySelector('.rental-item').textContent.toLowerCase();
            
            shouldShow = transactionId.includes(search.toLowerCase()) || 
                        userName.includes(search.toLowerCase()) || 
                        rentalItem.includes(search.toLowerCase());
        }
        
        // Filter berdasarkan status
        if (shouldShow && status !== 'Semua Status') {
            const badgeText = row.querySelector('.badge').textContent.trim();
            shouldShow = badgeText === status;
        }
        
        // Tampilkan atau sembunyikan row
        row.style.display = shouldShow ? '' : 'none';
    });
}

// Real-time search
searchInput.addEventListener('input', function() {
    const searchValue = this.value;
    const statusFilter = document.querySelectorAll('.filter-select')[0].value;
    const periodFilter = document.querySelectorAll('.filter-select')[1].value;
    
    filterTableData(searchValue, statusFilter, periodFilter);
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
        }
    });
});

nextBtn.addEventListener('click', function() {
    const currentActive = document.querySelector('.pagination-btn.active');
    console.log('Go to next page');
});

prevBtn.addEventListener('click', function() {
    const currentActive = document.querySelector('.pagination-btn.active');
    console.log('Go to previous page');
});

// Handle action buttons
const viewBtns = document.querySelectorAll('.view-btn');
const downloadBtns = document.querySelectorAll('.download-btn');

viewBtns.forEach(btn => {
    btn.addEventListener('click', function(e) {
        e.stopPropagation();
        const transactionId = this.closest('tr').querySelector('.transaction-id').textContent;
        console.log('View detail for:', transactionId);
        // Bisa membuka modal atau halaman detail
        alert('Lihat detail transaksi: ' + transactionId);
    });
});

downloadBtns.forEach(btn => {
    btn.addEventListener('click', function(e) {
        e.stopPropagation();
        const transactionId = this.closest('tr').querySelector('.transaction-id').textContent;
        console.log('Download receipt for:', transactionId);
        // Bisa mendownload dokumen/receipt
        alert('Download bukti: ' + transactionId);
    });
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
    console.log('Transaction page loaded');
    // Bisa menambahkan inisialisasi data dari API
});
