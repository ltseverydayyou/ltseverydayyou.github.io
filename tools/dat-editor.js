(()=>{
  const nav=document.querySelector('#nb');
  const main=document.querySelector('.l main');
  if(!nav||!main||document.querySelector('#pz'))return;

  const button=document.createElement('button');
  button.className='tb';
  button.dataset.t='z';
  button.textContent='DAT Editor';
  const converter=nav.querySelector('[data-t="i"]');
  if(converter)converter.insertAdjacentElement('afterend',button);else nav.appendChild(button);

  const panel=document.createElement('section');
  panel.id='pz';
  panel.className='pp';
  panel.innerHTML=`
    <div class="g dat-editor" id="dat-editor-root">
      <div class="dat-editor__hero" id="dat-drop-zone">
        <div class="dat-editor__intro">
          <span class="dat-editor__eyebrow">Binary editor</span>
          <h3>.DAT Hex Editor</h3>
          <p>Edit the actual bytes of a DAT file. Drop a file anywhere on this editor or open one manually.</p>
          <p class="dat-editor__meta" id="dat-meta">No file loaded.</p>
        </div>
        <div class="dat-editor__actions">
          <input id="dat-file-input" type="file" accept=".dat,application/octet-stream,*/*" hidden>
          <button class="pl sc" type="button" id="dat-open">Open file</button>
          <button class="pl" type="button" id="dat-save" disabled>Save file</button>
          <button class="pl" type="button" id="dat-reset" disabled>Revert</button>
        </div>
        <div class="dat-editor__drop-overlay" aria-hidden="true">
          <strong>Drop file to open</strong>
          <span>The file stays local in your browser.</span>
        </div>
      </div>

      <div class="dat-editor__panel">
        <div class="dat-editor__toolbar">
          <div class="dat-editor__toolbar-group">
            <label class="dat-editor__field dat-editor__goto">
              <span>Go to</span>
              <input id="dat-goto" type="text" inputmode="text" autocomplete="off" spellcheck="false" placeholder="0x00000000" disabled>
            </label>
            <button class="dat-editor__toolbtn" type="button" id="dat-goto-btn" disabled>Go</button>
          </div>
          <div class="dat-editor__toolbar-group">
            <label class="dat-editor__field dat-editor__find">
              <span>Find hex</span>
              <input id="dat-find" type="text" autocomplete="off" spellcheck="false" placeholder="DE AD BE EF" disabled>
            </label>
            <button class="dat-editor__toolbtn" type="button" id="dat-find-btn" disabled>Find next</button>
          </div>
          <div class="dat-editor__toolbar-group dat-editor__edit-actions">
            <button class="dat-editor__toolbtn" type="button" id="dat-insert" disabled>Insert 00</button>
            <button class="dat-editor__toolbtn" type="button" id="dat-delete" disabled>Delete byte</button>
          </div>
        </div>

        <div class="dat-editor__workspace">
          <div class="dat-editor__hex-shell">
            <div class="dat-editor__hex-header" aria-hidden="true">
              <div class="dat-editor__offset-head">Offset</div>
              <div class="dat-editor__byte-heads">${Array.from({length:16},(_,i)=>`<span>${i.toString(16).toUpperCase().padStart(2,'0')}</span>`).join('')}</div>
              <div class="dat-editor__ascii-head">ASCII</div>
            </div>
            <div class="dat-editor__viewport" id="dat-viewport" tabindex="0" role="grid" aria-label="Hexadecimal byte editor">
              <div class="dat-editor__empty" id="dat-empty">
                <strong>Drop a .dat file here</strong>
                <span>or use Open file above.</span>
              </div>
              <div class="dat-editor__spacer" id="dat-spacer"></div>
              <div class="dat-editor__rows" id="dat-rows"></div>
            </div>
          </div>

          <aside class="dat-editor__inspector">
            <h4>Selected byte</h4>
            <dl>
              <div><dt>Offset</dt><dd id="dat-ins-offset">—</dd></div>
              <div><dt>Hex</dt><dd id="dat-ins-hex">—</dd></div>
              <div><dt>Decimal</dt><dd id="dat-ins-dec">—</dd></div>
              <div><dt>Signed 8-bit</dt><dd id="dat-ins-signed">—</dd></div>
              <div><dt>ASCII</dt><dd id="dat-ins-ascii">—</dd></div>
            </dl>
            <div class="dat-editor__inspector-help">
              <strong>Keyboard</strong>
              <span>Type 0–9 / A–F to overwrite the selected byte. Arrow keys move. Page Up/Down jumps 16 rows.</span>
            </div>
          </aside>
        </div>

        <div class="dat-editor__statusbar">
          <span id="dat-status" aria-live="polite">Ready.</span>
          <span id="dat-position">Offset —</span>
        </div>
      </div>
    </div>`;
  main.appendChild(panel);

  const $=s=>panel.querySelector(s);
  const input=$('#dat-file-input');
  const openBtn=$('#dat-open');
  const saveBtn=$('#dat-save');
  const resetBtn=$('#dat-reset');
  const dropZone=$('#dat-drop-zone');
  const viewport=$('#dat-viewport');
  const spacer=$('#dat-spacer');
  const rowsLayer=$('#dat-rows');
  const empty=$('#dat-empty');
  const meta=$('#dat-meta');
  const status=$('#dat-status');
  const position=$('#dat-position');
  const gotoInput=$('#dat-goto');
  const gotoBtn=$('#dat-goto-btn');
  const findInput=$('#dat-find');
  const findBtn=$('#dat-find-btn');
  const insertBtn=$('#dat-insert');
  const deleteBtn=$('#dat-delete');
  const insOffset=$('#dat-ins-offset');
  const insHex=$('#dat-ins-hex');
  const insDec=$('#dat-ins-dec');
  const insSigned=$('#dat-ins-signed');
  const insAscii=$('#dat-ins-ascii');

  const BYTES_PER_ROW=16;
  const ROW_HEIGHT=28;
  const OVERSCAN=12;
  const MAX_FILE_SIZE=128*1024*1024;

  let bytes=null;
  let originalBytes=null;
  let currentName='edited.dat';
  let selectedIndex=-1;
  let pendingNibble=null;
  let dirty=false;
  let dragDepth=0;
  let renderedStart=-1;
  let renderedEnd=-1;
  let lastFindIndex=-1;

  function setStatus(message,error=false){
    status.textContent=message;
    status.dataset.error=error?'true':'false';
  }

  function formatOffset(index){
    return `0x${Math.max(0,index).toString(16).toUpperCase().padStart(8,'0')}`;
  }

  function printable(value){
    return value>=32&&value<=126?String.fromCharCode(value):'.';
  }

  function enableControls(enabled){
    saveBtn.disabled=!enabled;
    resetBtn.disabled=!enabled;
    gotoInput.disabled=!enabled;
    gotoBtn.disabled=!enabled;
    findInput.disabled=!enabled;
    findBtn.disabled=!enabled;
    insertBtn.disabled=!enabled;
    deleteBtn.disabled=!enabled;
  }

  function updateMeta(){
    if(!bytes){
      meta.textContent='No file loaded.';
      return;
    }
    meta.textContent=`${currentName} · ${bytes.length.toLocaleString()} bytes${dirty?' · modified':''}`;
  }

  function updateInspector(){
    if(!bytes||selectedIndex<0||selectedIndex>=bytes.length){
      insOffset.textContent='—';
      insHex.textContent='—';
      insDec.textContent='—';
      insSigned.textContent='—';
      insAscii.textContent='—';
      position.textContent='Offset —';
      return;
    }
    const value=bytes[selectedIndex];
    insOffset.textContent=formatOffset(selectedIndex);
    insHex.textContent=value.toString(16).toUpperCase().padStart(2,'0');
    insDec.textContent=String(value);
    insSigned.textContent=String(value>127?value-256:value);
    insAscii.textContent=printable(value);
    position.textContent=`Offset ${formatOffset(selectedIndex)} · ${selectedIndex.toLocaleString()} / ${(bytes.length-1).toLocaleString()}`;
  }

  function rowCount(){
    return bytes?Math.max(1,Math.ceil(bytes.length/BYTES_PER_ROW)):0;
  }

  function syncSpacer(){
    spacer.style.height=`${rowCount()*ROW_HEIGHT}px`;
  }

  function byteCell(index,value){
    const el=document.createElement('button');
    el.type='button';
    el.className='dat-editor__byte';
    el.dataset.index=String(index);
    el.setAttribute('role','gridcell');
    el.setAttribute('aria-label',`Byte ${formatOffset(index)}: ${value.toString(16).padStart(2,'0')}`);
    el.textContent=value.toString(16).toUpperCase().padStart(2,'0');
    if(index===selectedIndex)el.classList.add('is-selected');
    return el;
  }

  function asciiCell(index,value){
    const el=document.createElement('button');
    el.type='button';
    el.className='dat-editor__ascii-byte';
    el.dataset.index=String(index);
    el.tabIndex=-1;
    el.textContent=printable(value);
    el.setAttribute('aria-label',`ASCII byte ${formatOffset(index)}: ${printable(value)}`);
    if(index===selectedIndex)el.classList.add('is-selected');
    return el;
  }

  function renderRows(force=false){
    if(!bytes){
      rowsLayer.replaceChildren();
      spacer.style.height='0px';
      return;
    }
    const totalRows=rowCount();
    const visibleHeight=Math.max(viewport.clientHeight,300);
    const start=Math.max(0,Math.floor(viewport.scrollTop/ROW_HEIGHT)-OVERSCAN);
    const end=Math.min(totalRows,Math.ceil((viewport.scrollTop+visibleHeight)/ROW_HEIGHT)+OVERSCAN);
    if(!force&&start===renderedStart&&end===renderedEnd)return;
    renderedStart=start;
    renderedEnd=end;

    const frag=document.createDocumentFragment();
    for(let row=start;row<end;row++){
      const offset=row*BYTES_PER_ROW;
      const rowEl=document.createElement('div');
      rowEl.className='dat-editor__row';
      rowEl.style.transform=`translateY(${row*ROW_HEIGHT}px)`;
      rowEl.setAttribute('role','row');

      const off=document.createElement('div');
      off.className='dat-editor__offset';
      off.textContent=offset.toString(16).toUpperCase().padStart(8,'0');
      rowEl.appendChild(off);

      const hexGroup=document.createElement('div');
      hexGroup.className='dat-editor__bytes';
      const asciiGroup=document.createElement('div');
      asciiGroup.className='dat-editor__ascii';

      for(let col=0;col<BYTES_PER_ROW;col++){
        const index=offset+col;
        if(index<bytes.length){
          const value=bytes[index];
          hexGroup.appendChild(byteCell(index,value));
          asciiGroup.appendChild(asciiCell(index,value));
        }else{
          const blank=document.createElement('span');
          blank.className='dat-editor__byte dat-editor__byte--blank';
          hexGroup.appendChild(blank);
          const aBlank=document.createElement('span');
          aBlank.className='dat-editor__ascii-byte dat-editor__ascii-byte--blank';
          asciiGroup.appendChild(aBlank);
        }
      }
      rowEl.append(hexGroup,asciiGroup);
      frag.appendChild(rowEl);
    }
    rowsLayer.replaceChildren(frag);
  }

  function ensureVisible(index){
    if(!bytes||index<0)return;
    const row=Math.floor(index/BYTES_PER_ROW);
    const top=row*ROW_HEIGHT;
    const bottom=top+ROW_HEIGHT;
    const viewTop=viewport.scrollTop;
    const viewBottom=viewTop+viewport.clientHeight;
    if(top<viewTop)viewport.scrollTop=top;
    else if(bottom>viewBottom)viewport.scrollTop=Math.max(0,bottom-viewport.clientHeight);
  }

  function selectByte(index,{scroll=true,focus=false}={}){
    if(!bytes||!bytes.length){
      selectedIndex=-1;
      updateInspector();
      return;
    }
    selectedIndex=Math.max(0,Math.min(bytes.length-1,index));
    pendingNibble=null;
    if(scroll)ensureVisible(selectedIndex);
    renderRows(true);
    updateInspector();
    if(focus)viewport.focus({preventScroll:true});
  }

  function markDirty(message){
    dirty=true;
    updateMeta();
    setStatus(message||'Modified. Changes are not saved yet.');
  }

  function replaceByte(index,value,advance=false){
    if(!bytes||index<0||index>=bytes.length)return;
    bytes[index]=value&255;
    markDirty(`Changed ${formatOffset(index)} to ${bytes[index].toString(16).toUpperCase().padStart(2,'0')}.`);
    renderRows(true);
    updateInspector();
    if(advance&&index<bytes.length-1)selectByte(index+1,{scroll:true});
  }

  function insertByte(index,value=0){
    if(!bytes)return;
    const at=Math.max(0,Math.min(bytes.length,index));
    const next=new Uint8Array(bytes.length+1);
    next.set(bytes.subarray(0,at),0);
    next[at]=value&255;
    next.set(bytes.subarray(at),at+1);
    bytes=next;
    selectedIndex=at;
    pendingNibble=null;
    syncSpacer();
    markDirty(`Inserted 00 at ${formatOffset(at)}.`);
    renderRows(true);
    updateInspector();
    ensureVisible(selectedIndex);
  }

  function deleteByte(index){
    if(!bytes||!bytes.length||index<0||index>=bytes.length)return;
    const next=new Uint8Array(bytes.length-1);
    next.set(bytes.subarray(0,index),0);
    next.set(bytes.subarray(index+1),index);
    bytes=next;
    selectedIndex=bytes.length?Math.min(index,bytes.length-1):-1;
    pendingNibble=null;
    syncSpacer();
    markDirty(`Deleted byte at ${formatOffset(index)}.`);
    renderRows(true);
    updateInspector();
  }

  async function loadFile(file){
    if(!file)return;
    if(file.size>MAX_FILE_SIZE){
      setStatus(`File is ${(file.size/1024/1024).toFixed(1)} MB. This editor currently limits files to 128 MB for browser safety.`,true);
      return;
    }
    try{
      const loaded=new Uint8Array(await file.arrayBuffer());
      bytes=loaded.slice();
      originalBytes=loaded.slice();
      currentName=file.name||'edited.dat';
      selectedIndex=bytes.length?0:-1;
      pendingNibble=null;
      dirty=false;
      lastFindIndex=-1;
      viewport.scrollTop=0;
      empty.hidden=true;
      enableControls(true);
      syncSpacer();
      renderedStart=-1;
      renderedEnd=-1;
      renderRows(true);
      updateMeta();
      updateInspector();
      setStatus(`Loaded ${currentName}. ${bytes.length.toLocaleString()} bytes ready for binary editing.`);
    }catch(error){
      setStatus(error?.message||'Failed to load file.',true);
    }
  }

  function saveFile(){
    if(!bytes)return;
    try{
      const blob=new Blob([bytes],{type:'application/octet-stream'});
      const url=URL.createObjectURL(blob);
      const a=document.createElement('a');
      a.href=url;
      a.download=currentName;
      document.body.appendChild(a);
      a.click();
      a.remove();
      setTimeout(()=>URL.revokeObjectURL(url),0);
      dirty=false;
      updateMeta();
      setStatus(`Saved ${currentName} · ${bytes.length.toLocaleString()} bytes.`);
    }catch(error){
      setStatus(error?.message||'Could not save file.',true);
    }
  }

  function revertFile(){
    if(!originalBytes)return;
    bytes=originalBytes.slice();
    selectedIndex=bytes.length?Math.min(Math.max(selectedIndex,0),bytes.length-1):-1;
    pendingNibble=null;
    dirty=false;
    lastFindIndex=-1;
    syncSpacer();
    renderRows(true);
    updateMeta();
    updateInspector();
    setStatus('Reverted all changes to the originally opened file.');
  }

  function parseOffset(value){
    const raw=value.trim();
    if(!raw)return NaN;
    if(/^0x[0-9a-f]+$/i.test(raw))return parseInt(raw.slice(2),16);
    if(/^[0-9]+$/.test(raw))return parseInt(raw,10);
    if(/^[0-9a-f]+h$/i.test(raw))return parseInt(raw.slice(0,-1),16);
    return NaN;
  }

  function goToOffset(){
    if(!bytes||!bytes.length)return;
    const target=parseOffset(gotoInput.value);
    if(!Number.isFinite(target)||target<0||target>=bytes.length){
      setStatus(`Enter an offset between 0 and ${formatOffset(bytes.length-1)}. Hex: 0x20 or 20h. Decimal: 32.`,true);
      return;
    }
    selectByte(target,{scroll:true,focus:true});
    setStatus(`Jumped to ${formatOffset(target)}.`);
  }

  function parseHexPattern(value){
    const clean=value.trim().replace(/0x/gi,'').replace(/[^0-9a-f]/gi,'');
    if(!clean||clean.length%2)return null;
    const out=new Uint8Array(clean.length/2);
    for(let i=0;i<out.length;i++)out[i]=parseInt(clean.slice(i*2,i*2+2),16);
    return out;
  }

  function findNext(){
    if(!bytes||!bytes.length)return;
    const pattern=parseHexPattern(findInput.value);
    if(!pattern||!pattern.length){
      setStatus('Enter complete hexadecimal byte pairs, e.g. DE AD BE EF.',true);
      return;
    }
    if(pattern.length>bytes.length){
      setStatus('Pattern is longer than the loaded file.',true);
      return;
    }
    const start=Math.max(0,lastFindIndex+1);
    let found=-1;
    const search=(from,to)=>{
      outer:for(let i=from;i<=to-pattern.length;i++){
        for(let j=0;j<pattern.length;j++)if(bytes[i+j]!==pattern[j])continue outer;
        return i;
      }
      return -1;
    };
    found=search(start,bytes.length);
    if(found<0&&start>0)found=search(0,start);
    if(found<0){
      setStatus('Hex pattern not found.',true);
      return;
    }
    lastFindIndex=found;
    selectByte(found,{scroll:true,focus:true});
    setStatus(`Found ${pattern.length} byte${pattern.length===1?'':'s'} at ${formatOffset(found)}.`);
  }

  function handleHexKey(key){
    if(!bytes||selectedIndex<0||!/^[0-9a-f]$/i.test(key))return false;
    const nibble=parseInt(key,16);
    if(pendingNibble===null){
      pendingNibble=nibble;
      const preview=(nibble<<4)|(bytes[selectedIndex]&0x0F);
      bytes[selectedIndex]=preview;
      markDirty(`Editing ${formatOffset(selectedIndex)}…`);
      renderRows(true);
      updateInspector();
    }else{
      bytes[selectedIndex]=(pendingNibble<<4)|nibble;
      pendingNibble=null;
      const old=selectedIndex;
      markDirty(`Changed ${formatOffset(old)} to ${bytes[old].toString(16).toUpperCase().padStart(2,'0')}.`);
      if(selectedIndex<bytes.length-1)selectByte(selectedIndex+1,{scroll:true});
      else{renderRows(true);updateInspector();}
    }
    return true;
  }

  function handleViewportKeydown(event){
    if(!bytes||selectedIndex<0)return;
    if(handleHexKey(event.key)){
      event.preventDefault();
      return;
    }
    let target=selectedIndex;
    switch(event.key){
      case 'ArrowLeft':target--;break;
      case 'ArrowRight':target++;break;
      case 'ArrowUp':target-=BYTES_PER_ROW;break;
      case 'ArrowDown':target+=BYTES_PER_ROW;break;
      case 'PageUp':target-=BYTES_PER_ROW*16;break;
      case 'PageDown':target+=BYTES_PER_ROW*16;break;
      case 'Home':target=Math.floor(selectedIndex/BYTES_PER_ROW)*BYTES_PER_ROW;break;
      case 'End':target=Math.min(bytes.length-1,Math.floor(selectedIndex/BYTES_PER_ROW)*BYTES_PER_ROW+15);break;
      case 'Delete':deleteByte(selectedIndex);event.preventDefault();return;
      case 'Insert':insertByte(selectedIndex,0);event.preventDefault();return;
      default:return;
    }
    event.preventDefault();
    selectByte(target,{scroll:true});
  }

  openBtn.addEventListener('click',()=>input.click());
  input.addEventListener('change',()=>{
    const file=input.files?.[0];
    if(file)loadFile(file);
    input.value='';
  });
  saveBtn.addEventListener('click',saveFile);
  resetBtn.addEventListener('click',revertFile);
  gotoBtn.addEventListener('click',goToOffset);
  gotoInput.addEventListener('keydown',e=>{if(e.key==='Enter'){e.preventDefault();goToOffset();}});
  findBtn.addEventListener('click',findNext);
  findInput.addEventListener('keydown',e=>{if(e.key==='Enter'){e.preventDefault();findNext();}});
  insertBtn.addEventListener('click',()=>insertByte(selectedIndex>=0?selectedIndex:bytes?.length||0,0));
  deleteBtn.addEventListener('click',()=>deleteByte(selectedIndex));

  viewport.addEventListener('scroll',()=>renderRows(false),{passive:true});
  viewport.addEventListener('keydown',handleViewportKeydown);
  viewport.addEventListener('click',event=>{
    const target=event.target.closest('[data-index]');
    if(!target||!viewport.contains(target))return;
    const index=Number(target.dataset.index);
    if(Number.isInteger(index))selectByte(index,{scroll:false,focus:true});
  });

  panel.addEventListener('dragenter',event=>{
    if(!event.dataTransfer?.types?.includes('Files'))return;
    event.preventDefault();
    dragDepth++;
    dropZone.classList.add('is-dragging');
  });
  panel.addEventListener('dragover',event=>{
    if(!event.dataTransfer?.types?.includes('Files'))return;
    event.preventDefault();
    event.dataTransfer.dropEffect='copy';
    dropZone.classList.add('is-dragging');
  });
  panel.addEventListener('dragleave',event=>{
    if(!event.dataTransfer?.types?.includes('Files'))return;
    dragDepth=Math.max(0,dragDepth-1);
    if(!dragDepth)dropZone.classList.remove('is-dragging');
  });
  panel.addEventListener('drop',event=>{
    if(!event.dataTransfer?.files?.length)return;
    event.preventDefault();
    dragDepth=0;
    dropZone.classList.remove('is-dragging');
    loadFile(event.dataTransfer.files[0]);
  });

  window.addEventListener('resize',()=>renderRows(true),{passive:true});
})();
