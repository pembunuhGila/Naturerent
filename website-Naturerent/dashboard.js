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

// Handle quick access cards - already links with href
const quickCards = document.querySelectorAll('.quick-card');
quickCards.forEach(card => {
    card.addEventListener('click', function(e) {
        // Link will navigate automatically
        console.log('Navigate to:', this.getAttribute('href'));
    });
});

// Handle user profile click
const userProfile = document.querySelector('.user-profile');
userProfile.addEventListener('click', function() {
    console.log('Show user profile menu');
    // Bisa menampilkan menu dropdown untuk user settings
});

// Stat card hover animation
const statCards = document.querySelectorAll('.stat-card');
statCards.forEach(card => {
    card.addEventListener('mouseenter', function() {
        this.style.transform = 'translateY(-4px)';
    });
    card.addEventListener('mouseleave', function() {
        this.style.transform = 'translateY(0)';
    });
});

// Initialize
document.addEventListener('DOMContentLoaded', function() {
    console.log('Dashboard page loaded');
    // Bisa menambahkan inisialisasi data dari API
});
