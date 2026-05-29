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

// Handle sidebar navigation (Komisi removed from this page to avoid redundancy)
const navItems = document.querySelectorAll('.nav-item');
navItems.forEach(item => {
    item.addEventListener('click', function() {
        const page = this.querySelector('span').textContent;
        
        navItems.forEach(nav => nav.classList.remove('active'));
        this.classList.add('active');
        
        if (page === 'Dashboard') {
            window.location.href = 'dashboard.html';
        } else if (page === 'Pemilik Rental') {
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

    // Map modal logic: open when clicking a location cell
    let mapInstance = null;

    function openMap(lat, lng, title) {
        const modal = document.getElementById('mapModal');
        const mapEl = document.getElementById('map');
        modal.style.display = 'flex';

        // Remove previous map instance if any
        if (mapInstance) {
            try { mapInstance.remove(); } catch (e) { /* ignore */ }
            mapInstance = null;
        }

        mapInstance = L.map(mapEl).setView([lat, lng], 13);
        L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
            maxZoom: 19,
            attribution: '&copy; OpenStreetMap contributors'
        }).addTo(mapInstance);

        L.marker([lat, lng]).addTo(mapInstance).bindPopup(title || 'Lokasi').openPopup();
        setTimeout(() => { mapInstance.invalidateSize(); }, 200);
    }

    function closeMap() {
        const modal = document.getElementById('mapModal');
        modal.style.display = 'none';
        if (mapInstance) {
            try { mapInstance.remove(); } catch (e) { /* ignore */ }
            mapInstance = null;
        }
    }

    document.getElementById('closeMap').addEventListener('click', closeMap);
    document.getElementById('mapModal').addEventListener('click', function(e) {
        if (e.target === this) closeMap();
    });

    // Attach click handlers to location cells (they have data-lat and data-lng)
    const locationCells = document.querySelectorAll('.location.clickable');
    locationCells.forEach(cell => {
        cell.style.cursor = 'pointer';
        cell.addEventListener('click', function() {
            const lat = parseFloat(this.dataset.lat);
            const lng = parseFloat(this.dataset.lng);
            const title = this.textContent.trim();
            if (!isNaN(lat) && !isNaN(lng)) {
                openMap(lat, lng, title);
            } else {
                alert('Koordinat tidak tersedia untuk lokasi ini.');
            }
        });
    });
});
