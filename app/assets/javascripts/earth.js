// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.

window.onkeydown = function(key) {respond_to_keypress(key)} 
setInterval(updateUnits, 2000);

function respond_to_keypress(event) {
  keymap = {
    87: 'up',       // w
    83: 'down',     // s
    65: 'left',     // a
    68: 'right',    // d
    81: 'counter',  // q
    69: 'clock',    // e
  };

  link_id = "nav_" + keymap[event.keyCode]
  document.getElementById(link_id).click()
};

function updateUnits() {
  if (document.getElementById('refresh-button').dataset['toggle'] != 'on') {
    // Allow us to turn refresh off if we want to sit there and stare at the DOM
    return;
  }

  pageData = document.getElementById('datastore').dataset

  map_container = document.getElementById('map-container');
  grid = map_container.dataset.centerGrid;
  radius = map_container.dataset.radius;

  MOVE_ICON_PATH = pageData['iconMove']
  COMBAT_ICON_PATH = pageData['iconCombat']

  $.ajax({
    url: window.location.origin + '/troops/' + grid + '/' + radius,
    dataType:'json',
    type: 'get',
    success: function(response){
      // response is a hash of grid-ids to hashes of unit data

      // first remove units currently on the map, saving whether they
      // are expanded or not
      states = {};
      $(".troop-slot").each(function(index, troop) {
        states[troop.dataset.unitId] = troop.dataset.toggle
      });

      $(".troop-slot").remove()

      for (grid_id in response) { 
      // now go through and re-add them
        unitlist = response[grid_id];  
        html_to_insert = '';
        // for each unit
        for (index in unitlist) {
          unit = unitlist[index];
          unit_state = states[unit.id];

          move_icon_html = unit.moving ? `<img class="move-icon" src="${MOVE_ICON_PATH}">` : `` 
          combat_icon_html = unit.fighting ? `<img class="combat-icon" src="${COMBAT_ICON_PATH}">` : ``


          unit_orders = ``;
          unit.orders.forEach(function(order_hash) {
            unit_orders += `<p>${order_hash['command']} (${order_hash.target})</p>`
          });

          unit_popup_html = `
            <div class="unit-popup">
              <span class="left-col">
                <b>${unit.name}</b><br/>
                (${unit.hp}/${unit.max_hp}) hp<br/>
                acts in: ${unit.next_event_in}<br/>
              </span>
              <span class="right-col">
                <b>Orders</b>
                ${unit_orders}
              </span>
            </div>
          `;

          new_html = `
          <div
            class="troop-slot element-toggle ${unit_state == 'on' ? 'on' : 'off'}"
            id="unit-${unit.id}"
            onclick="toggleElement(this)"
            data-toggle="${unit_state == 'on' ? 'on' : 'off'}"
            data-unit-id="${unit.id}"
          >
            <img src="${unit.asset_path}" class="unit-icon">
            <!-- Movement Icon --> 
                ${move_icon_html}
            <div class="unit-data">
                "${unit.name} (${unit.hp}/${unit.max_hp} hp)"
            </div>
            <!-- Combat Icon -->
                ${combat_icon_html}
            ${unit_popup_html}
          </div>
          `;
          html_to_insert = html_to_insert + new_html;
        }
        $('#grid-' + grid_id).find('.unit-container')[0].innerHTML = html_to_insert;
      }
    }
  });
}


function toggleButton(button) {
  btn = $(button)
  btn.toggleClass('on')
  btn.toggleClass('off')
  button.dataset['toggle'] = button.dataset['toggle'] == 'on' ? 'off' : 'on'
}


function toggleElement(el) {
  $el = $(el)
  $el.toggleClass('on')
  $el.toggleClass('off')
  el.dataset['toggle'] = el.dataset['toggle'] == 'on' ? 'off' : 'on'
}


// w: 87
// s: 83
// a: 65
// d: 68
// q: 81
// e: 69
