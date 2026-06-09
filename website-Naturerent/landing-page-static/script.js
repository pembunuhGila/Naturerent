/* ========================================
   NATURERENT LANDING PAGE - ADVANCED INTERACTIVITY
   ======================================== */

document.addEventListener('DOMContentLoaded', function() {
    
    // ========== SMOOTH SCROLL FOR NAVIGATION ==========
    const navLinks = document.querySelectorAll('.navbar-menu a');
    navLinks.forEach(link => {
        link.addEventListener('click', function(e) {
            e.preventDefault();
            const targetId = this.getAttribute('href');
            const targetSection = document.querySelector(targetId);
            if (targetSection) {
                targetSection.scrollIntoView({ behavior: 'smooth' });
                // Highlight active link
                navLinks.forEach(l => l.style.color = 'var(--text)');
                this.style.color = 'var(--primary)';
            }
        });
    });

    // ========== COUNTER ANIMATION FOR STATS ==========
    const statValues = document.querySelectorAll('.stat-value[data-count]');
    const observerOptions = {
        threshold: 0.5,
        rootMargin: '0px'
    };

    const counterObserver = new IntersectionObserver(function(entries) {
        entries.forEach(entry => {
            if (entry.isIntersecting && !entry.target.classList.contains('counted')) {
                const target = entry.target;
                const finalCount = parseInt(target.getAttribute('data-count'));
                animateCounter(target, finalCount);
                target.classList.add('counted');
                counterObserver.unobserve(target);
            }
        });
    }, observerOptions);

    statValues.forEach(stat => {
        if (!stat.getAttribute('data-count').includes('.')) {
            counterObserver.observe(stat);
        }
    });

    // ========== PARALLAX EFFECT ==========
    window.addEventListener('scroll', function() {
        const hero = document.querySelector('.hero-visual');
        if (hero) {
            const scrollPosition = window.pageYOffset;
            hero.style.transform = `translateY(${scrollPosition * 0.3}px)`;
        }
    });

    // ========== NAVBAR EFFECT ON SCROLL ==========
    const navbar = document.querySelector('.navbar');
    let lastScrollTop = 0;

    window.addEventListener('scroll', function() {
        const scrollTop = window.pageYOffset || document.documentElement.scrollTop;
        
        if (scrollTop > 50) {
            navbar.style.boxShadow = '0 4px 12px rgba(0, 0, 0, 0.15)';
            navbar.style.background = 'rgba(255, 255, 255, 0.95)';
            navbar.style.backdropFilter = 'blur(10px)';
        } else {
            navbar.style.boxShadow = '0 1px 2px rgba(0, 0, 0, 0.05)';
            navbar.style.background = 'var(--white)';
            navbar.style.backdropFilter = 'none';
        }
        lastScrollTop = scrollTop;
    });

    // ========== INTERSECTION OBSERVER FOR ANIMATIONS ==========
    const animateOnScroll = (selector) => {
        const elements = document.querySelectorAll(selector);
        const observer = new IntersectionObserver(function(entries) {
            entries.forEach(entry => {
                if (entry.isIntersecting) {
                    entry.target.style.opacity = '1';
                    entry.target.style.transform = 'translateY(0)';
                    observer.unobserve(entry.target);
                }
            });
        }, {
            threshold: 0.1,
            rootMargin: '0px 0px -50px 0px'
        });

        elements.forEach(el => {
            el.style.opacity = '0';
            el.style.transform = 'translateY(30px)';
            el.style.transition = 'opacity 0.6s ease-out, transform 0.6s ease-out';
            observer.observe(el);
        });
    };

    // Apply animations to cards
    animateOnScroll('.feature-card');
    animateOnScroll('.problem-card');
    animateOnScroll('.step-card');
    animateOnScroll('.benefit-card');
    animateOnScroll('.testimonial-card');
    animateOnScroll('.stat-card');
    animateOnScroll('.badge-item');
    animateOnScroll('.comparison-row');

    // ========== COMPARISON ROW STAGGER EFFECT ==========
    const comparisonRows = document.querySelectorAll('.comparison-row');
    comparisonRows.forEach((row, index) => {
        row.style.setProperty('--delay', `${index * 50}ms`);
        row.style.opacity = '0';
        row.style.transform = 'translateX(-20px)';
        row.style.transition = `opacity 0.6s ease-out ${index * 50}ms, transform 0.6s ease-out ${index * 50}ms`;
        
        setTimeout(() => {
            row.style.opacity = '1';
            row.style.transform = 'translateX(0)';
        }, 100);
    });

    // ========== DOWNLOAD BUTTON INTERACTIONS ==========
    const downloadButtons = document.querySelectorAll('[class*="btn-primary"], [class*="download-btn"]');
    downloadButtons.forEach(btn => {
        btn.addEventListener('click', function(e) {
            if (this.hasAttribute('href') && this.getAttribute('href').startsWith('http')) {
                return;
            }
            
            if (!this.hasAttribute('href') || this.getAttribute('href') === '#') {
                e.preventDefault();
                showNotification('✨ Aplikasi NatureRent segera tersedia di Google Play & App Store!');
            }
        });

        // Add ripple effect
        btn.addEventListener('mousedown', function(e) {
            const ripple = document.createElement('span');
            const rect = this.getBoundingClientRect();
            const size = Math.max(rect.width, rect.height);
            const x = e.clientX - rect.left - size / 2;
            const y = e.clientY - rect.top - size / 2;

            ripple.style.cssText = `
                width: ${size}px;
                height: ${size}px;
                background: rgba(255, 255, 255, 0.5);
                border-radius: 50%;
                position: absolute;
                left: ${x}px;
                top: ${y}px;
                animation: ripple 0.6s ease-out;
            `;
            
            this.style.position = 'relative';
            this.style.overflow = 'hidden';
            this.appendChild(ripple);

            setTimeout(() => ripple.remove(), 600);
        });
    });

    // ========== FEATURE ICON ROTATION ==========
    const featureIcons = document.querySelectorAll('.feature-icon, .problem-icon, .stat-icon, .badge-icon');
    featureIcons.forEach(icon => {
        icon.addEventListener('mouseenter', function() {
            this.style.transform = 'scale(1.1) rotate(10deg)';
            this.style.transition = 'transform 0.3s ease-out';
        });
        icon.addEventListener('mouseleave', function() {
            this.style.transform = 'scale(1) rotate(0deg)';
        });
    });

    // ========== CARD HOVER EFFECTS ==========
    const allCards = document.querySelectorAll('.feature-card, .problem-card, .step-card, .benefit-card, .testimonial-card, .stat-card, .badge-item');
    allCards.forEach(card => {
        card.addEventListener('mouseenter', function() {
            this.style.boxShadow = '0 20px 40px rgba(0, 0, 0, 0.2)';
        });
        card.addEventListener('mouseleave', function() {
            this.style.boxShadow = '';
        });
    });

    // ========== SCROLL TO TOP BUTTON ==========
    const scrollTopBtn = createScrollTopButton();
    window.addEventListener('scroll', function() {
        if (window.pageYOffset > 300) {
            scrollTopBtn.style.opacity = '1';
            scrollTopBtn.style.pointerEvents = 'auto';
        } else {
            scrollTopBtn.style.opacity = '0';
            scrollTopBtn.style.pointerEvents = 'none';
        }
    });

    // ========== ACTIVE NAV LINK UPDATE ==========
    window.addEventListener('scroll', updateActiveNavLink);
    updateActiveNavLink();
});

// ========== HELPER FUNCTIONS ==========

function animateCounter(element, targetValue) {
    let currentValue = 0;
    const increment = targetValue / 60;
    const duration = 2000;
    const startTime = Date.now();

    function updateCounter() {
        const elapsed = Date.now() - startTime;
        const progress = Math.min(elapsed / duration, 1);
        
        currentValue = Math.floor(progress * targetValue);
        element.textContent = currentValue.toLocaleString('id-ID');
        
        if (progress < 1) {
            requestAnimationFrame(updateCounter);
        } else {
            element.textContent = targetValue.toLocaleString('id-ID');
        }
    }

    updateCounter();
}

function showNotification(message) {
    const notification = document.createElement('div');
    notification.style.cssText = `
        position: fixed;
        top: 20px;
        right: 20px;
        background: linear-gradient(135deg, #14532D 0%, #0f3d24 100%);
        color: white;
        padding: 16px 24px;
        border-radius: 12px;
        box-shadow: 0 10px 30px rgba(0, 0, 0, 0.3);
        z-index: 1000;
        max-width: 400px;
        font-size: 14px;
        font-weight: 500;
        animation: slideIn 0.4s cubic-bezier(0.34, 1.56, 0.64, 1);
        border-left: 4px solid #4ade80;
    `;
    notification.textContent = message;
    
    document.body.appendChild(notification);
    
    setTimeout(() => {
        notification.style.animation = 'slideOut 0.4s ease-out';
        setTimeout(() => {
            document.body.removeChild(notification);
        }, 400);
    }, 4000);
}

function createScrollTopButton() {
    const btn = document.createElement('button');
    btn.innerHTML = '<i class=\"fas fa-arrow-up\"></i>';
    btn.style.cssText = `
        position: fixed;
        bottom: 30px;
        right: 30px;
        width: 50px;
        height: 50px;
        background: linear-gradient(135deg, #14532D 0%, #0f3d24 100%);
        color: white;
        border: none;
        border-radius: 50%;
        cursor: pointer;
        opacity: 0;
        pointer-events: none;
        transition: all 0.3s ease;
        box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
        z-index: 999;
        font-size: 1.2rem;
    `;

    btn.addEventListener('click', () => {
        window.scrollTo({ top: 0, behavior: 'smooth' });
    });

    btn.addEventListener('mouseenter', function() {
        this.style.transform = 'translateY(-5px)';
        this.style.boxShadow = '0 8px 20px rgba(0, 0, 0, 0.2)';
    });

    btn.addEventListener('mouseleave', function() {
        this.style.transform = 'translateY(0)';
        this.style.boxShadow = '0 4px 12px rgba(0, 0, 0, 0.15)';
    });

    document.body.appendChild(btn);
    return btn;
}

function updateActiveNavLink() {
    const sections = document.querySelectorAll('section[id]');
    const navLinks = document.querySelectorAll('.navbar-menu a');

    sections.forEach(section => {
        const sectionTop = section.offsetTop;
        const sectionHeight = section.clientHeight;
        
        if (window.pageYOffset >= sectionTop - 100) {
            navLinks.forEach(link => {
                link.style.color = 'var(--text)';
                if (link.getAttribute('href') === `#${section.id}`) {
                    link.style.color = 'var(--primary)';
                    link.style.fontWeight = '600';
                }
            });
        }
    });
}

// ========== ADD ANIMATION KEYFRAMES ==========
if (!document.querySelector('style[data-custom-animations]')) {
    const style = document.createElement('style');
    style.setAttribute('data-custom-animations', 'true');
    style.textContent = `
        @keyframes slideIn {
            from {
                transform: translateX(400px);
                opacity: 0;
            }
            to {
                transform: translateX(0);
                opacity: 1;
            }
        }
        
        @keyframes slideOut {
            from {
                transform: translateX(0);
                opacity: 1;
            }
            to {
                transform: translateX(400px);
                opacity: 0;
            }
        }

        @keyframes ripple {
            from {
                transform: scale(0);
                opacity: 1;
            }
            to {
                transform: scale(4);
                opacity: 0;
            }
        }

        @keyframes float {
            0%, 100% {
                transform: translateY(0px);
            }
            50% {
                transform: translateY(-10px);
            }
        }

        @keyframes pulse {
            0%, 100% {
                opacity: 1;
            }
            50% {
                opacity: 0.5;
            }
        }
    `;
    document.head.appendChild(style);
}
