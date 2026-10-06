/* Analia Carolini Belleza — interacciones propias (prefijo ac-) */
(function () {
  var reduceMotion = window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches;

  /* ---------- Animaciones de entrada ---------- */
  function initReveal() {
    var els = document.querySelectorAll('.ac-reveal:not(.ac-visible)');
    if (!els.length) return;
    if (reduceMotion || !('IntersectionObserver' in window)) {
      els.forEach(function (el) { el.classList.add('ac-visible'); });
      return;
    }
    var io = new IntersectionObserver(function (entries) {
      entries.forEach(function (entry) {
        if (entry.isIntersecting) {
          entry.target.classList.add('ac-visible');
          io.unobserve(entry.target);
        }
      });
    }, { threshold: 0.12, rootMargin: '0px 0px -40px 0px' });
    els.forEach(function (el) { io.observe(el); });
  }

  /* ---------- Selector "7 colores, 7 cuidados" ---------- */
  function initColores(root) {
    root.querySelectorAll('[data-ac-colores]').forEach(function (box) {
      if (box.dataset.acReady) return;
      box.dataset.acReady = '1';
      var chips = box.querySelectorAll('[data-ac-chip]');
      var panels = box.querySelectorAll('[data-ac-panel]');
      var auto = parseInt(box.dataset.autoplay || '0', 10);
      var current = 0;
      var timer = null;

      function select(i, fromUser) {
        current = i;
        chips.forEach(function (chip, n) { chip.setAttribute('aria-selected', n === i ? 'true' : 'false'); chip.tabIndex = n === i ? 0 : -1; });
        panels.forEach(function (panel, n) { panel.hidden = n !== i; });
        box.style.setProperty('--ac-color', chips[i].dataset.color);
        if (fromUser && timer) { clearInterval(timer); timer = null; }
      }
      chips.forEach(function (chip, i) {
        chip.addEventListener('click', function () { select(i, true); });
        chip.addEventListener('keydown', function (e) {
          if (e.key === 'ArrowRight' || e.key === 'ArrowLeft') {
            e.preventDefault();
            var next = (current + (e.key === 'ArrowRight' ? 1 : -1) + chips.length) % chips.length;
            select(next, true);
            chips[next].focus();
          }
        });
      });
      if (chips.length) select(0, false);
      if (auto > 0 && !reduceMotion && chips.length > 1) {
        timer = setInterval(function () { select((current + 1) % chips.length, false); }, auto * 1000);
      }
    });
  }

  /* ---------- Página de producto ---------- */
  function money(cents, format) {
    var value = (cents / 100).toFixed(2);
    var parts = value.split('.');
    var miles = parts[0].replace(/\B(?=(\d{3})+(?!\d))/g, '.');
    var conDecimales = miles + ',' + parts[1];
    if (!format) return '$' + conDecimales;
    return format.replace(/\{\{\s*(\w+)\s*\}\}/, function (_, key) {
      if (key === 'amount_no_decimals' || key === 'amount_no_decimals_with_comma_separator') return miles;
      if (key === 'amount_with_comma_separator') return conDecimales;
      if (key === 'amount') return parts[0].replace(/\B(?=(\d{3})+(?!\d))/g, ',') + '.' + parts[1];
      return conDecimales;
    });
  }

  function initProducto(root) {
    root.querySelectorAll('[data-ac-pdp]').forEach(function (pdp) {
      if (pdp.dataset.acReady) return;
      pdp.dataset.acReady = '1';

      // Galería
      var main = pdp.querySelector('[data-ac-main]');
      pdp.querySelectorAll('[data-ac-thumb]').forEach(function (thumb) {
        thumb.addEventListener('click', function () {
          pdp.querySelectorAll('[data-ac-thumb]').forEach(function (t) { t.setAttribute('aria-current', 'false'); });
          thumb.setAttribute('aria-current', 'true');
          main.style.opacity = '0';
          setTimeout(function () {
            main.src = thumb.dataset.src;
            main.srcset = thumb.dataset.srcset || '';
            main.alt = thumb.dataset.alt || '';
            main.style.opacity = '1';
          }, 180);
        });
      });

      // Cantidad
      var qty = pdp.querySelector('[data-ac-qty]');
      pdp.querySelectorAll('[data-ac-qty-btn]').forEach(function (btn) {
        btn.addEventListener('click', function () {
          var v = parseInt(qty.value || '1', 10) + parseInt(btn.dataset.acQtyBtn, 10);
          qty.value = Math.max(1, v);
        });
      });

      // Variantes
      var dataEl = pdp.querySelector('[data-ac-variants]');
      var variants = dataEl ? JSON.parse(dataEl.textContent) : [];
      var idInput = pdp.querySelector('input[name="id"]');
      var buyBtns = document.querySelectorAll('[data-ac-buy-btn]');
      var priceNow = document.querySelectorAll('[data-ac-price]');
      var priceOld = pdp.querySelector('[data-ac-price-old]');
      var format = pdp.dataset.moneyFormat;
      function onOptionChange() {
        var chosen = [];
        pdp.querySelectorAll('[data-ac-option]').forEach(function (fs) {
          var checked = fs.querySelector('input:checked');
          chosen.push(checked ? checked.value : null);
        });
        var v = variants.find(function (variant) {
          return variant.options.every(function (opt, i) { return opt === chosen[i]; });
        });
        buyBtns.forEach(function (b) {
          var label = b.querySelector('[data-ac-buy-label]');
          if (!v) { b.disabled = true; if (label) label.textContent = pdp.dataset.textUnavailable; return; }
          b.disabled = !v.available;
          if (label) label.textContent = v.available ? pdp.dataset.textAdd : pdp.dataset.textSoldout;
        });
        if (!v) return;
        idInput.value = v.id;
        priceNow.forEach(function (p) { p.textContent = money(v.price, format); });
        if (priceOld) {
          priceOld.hidden = !(v.compare_at_price && v.compare_at_price > v.price);
          if (v.compare_at_price) priceOld.textContent = money(v.compare_at_price, format);
        }
        var url = new URL(window.location.href);
        url.searchParams.set('variant', v.id);
        window.history.replaceState({}, '', url.toString());
      }
      pdp.querySelectorAll('[data-ac-option] input').forEach(function (input) { input.addEventListener('change', onOptionChange); });

      // Añadir al carrito sin salir de la página (abre el carrito del tema)
      var form = pdp.querySelector('form[data-ac-form]');
      var msg = pdp.querySelector('[data-ac-msg]');
      if (form && window.fetch) {
        form.addEventListener('submit', function (e) {
          var cart = document.querySelector('cart-drawer') || document.querySelector('cart-notification');
          if (!cart || typeof cart.renderContents !== 'function') return; // envío normal
          e.preventDefault();
          var btn = form.querySelector('[type="submit"]');
          btn.disabled = true;
          if (msg) { msg.textContent = ''; msg.classList.remove('ac-pdp__msg--error'); }
          var body = new FormData(form);
          body.append('sections', cart.getSectionsToRender().map(function (s) { return s.id; }).join(','));
          body.append('sections_url', window.location.pathname);
          fetch((window.routes && window.routes.cart_add_url ? window.routes.cart_add_url : '/cart/add') + '.js', {
            method: 'POST', headers: { 'X-Requested-With': 'XMLHttpRequest', Accept: 'application/json' }, body: body
          })
            .then(function (r) { return r.json(); })
            .then(function (res) {
              if (res.status) {
                if (msg) { msg.textContent = res.description || res.message; msg.classList.add('ac-pdp__msg--error'); }
                return;
              }
              cart.classList.remove('is-empty');
              var drawerInner = cart.querySelector('.drawer__inner');
              if (drawerInner) drawerInner.classList.remove('is-empty');
              cart.renderContents(res);
            })
            .catch(function () { form.submit(); })
            .finally(function () { btn.disabled = false; });
        });
      }

      // Barra fija de compra en móvil
      var sticky = document.querySelector('[data-ac-sticky-buy]');
      var buyZone = pdp.querySelector('[data-ac-buy-zone]');
      if (sticky && buyZone && 'IntersectionObserver' in window) {
        new IntersectionObserver(function (entries) {
          entries.forEach(function (entry) {
            var below = entry.boundingClientRect.top < 0;
            sticky.classList.toggle('ac-visible', !entry.isIntersecting && below);
          });
        }).observe(buyZone);
        var stickyBtn = sticky.querySelector('button');
        if (stickyBtn) stickyBtn.addEventListener('click', function () {
          if (form.requestSubmit) form.requestSubmit(); else form.submit();
        });
      }
    });
  }

  function initAll(root) {
    initReveal();
    initColores(root || document);
    initProducto(root || document);
  }

  document.addEventListener('DOMContentLoaded', function () { initAll(document); });
  // Editor de Shopify: re-inicializar al añadir o editar secciones
  document.addEventListener('shopify:section:load', function (e) { initAll(e.target); });
})();
