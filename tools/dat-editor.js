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
          <p>Edit raw bytes locally in your browser. Drop a file anywhere on this editor or open one manually.</p>
          <p class="dat-editor__meta" id="dat-meta">No file loaded.</p>
        </div>
        <div class="dat-editor__actions">
          <input id="dat-file-input" type="file" accept=".dat,application/octet-stream,*/*" hidden>
          <button class="pl sc" type="button" id="dat-open">Open file</button>
          <button class="pl" type="button" id="dat-save" disabled>Save file</button>
          <button class="pl" type="button" id="dat-undo" disabled>Undo</button>
          <button class="pl" type="button" id="dat-redo" disabled>Redo</button>
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

          <div class="dat-editor__toolbar-group dat-editor__search-group">
            <label class="dat-editor__field dat-editor__find">
              <span>Find hex</span>
              <input id="dat-find" type="text" autocomplete="off" spellcheck="false" placeholder="DE AD ?? EF" disabled>
            </label>
            <label class="dat-editor__field dat-editor__replace">
              <span>Replace with</span>
              <input id="dat-replace" type="text" autocomplete="off" spellcheck="false" placeholder="00 00 00 00" disabled>
            </label>
            <button class="dat-editor__toolbtn" type="button" id="dat-find-btn" disabled>Find next</button>
            <button class="dat-editor__toolbtn" type="button" id="dat-replace-btn" disabled>Replace</button>
            <button class="dat-editor__toolbtn" type="button" id="dat-replace-all-btn" disabled>Replace all</button>
          </div>

          <div class="dat-editor__toolbar-group dat-editor__bookmark-actions">
            <button class="dat-editor__toolbtn" type="button" id="dat-bookmark" disabled>Bookmark</button>
            <label class="dat-editor__field dat-editor__bookmark-field">
              <span>Bookmarks</span>
              <select id="dat-bookmarks" disabled><option value="">None</option></select>
            </label>
          </div>

          <div class="dat-editor__toolbar-group dat-editor__edit-actions">
            <button class="dat-editor__toolbtn" type="button" id="dat-insert" disabled>Insert 00</button>
            <button class="dat-editor__toolbtn" type="button" id="dat-delete" disabled>Delete</button>
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
            <div class="dat-editor__inspector-head">
              <h4>Data inspector</h4>
              <select id="dat-endian" aria-label="Byte order">
                <option value="le">Little endian</option>
                <option value="be">Big endian</option>
              </select>
            </div>
            <dl>
              <div><dt>Offset</dt><dd id="dat-ins-offset">—</dd></div>
              <div><dt>Selection</dt><dd id="dat-ins-selection">—</dd></div>
              <div><dt>Hex / ASCII</dt><dd><span id="dat-ins-hex">—</span> · <span id="dat-ins-ascii">—</span></dd></div>
              <div><dt>UInt8 / Int8</dt><dd><span id="dat-ins-u8">—</span> / <span id="dat-ins-i8">—</span></dd></div>
              <div><dt>UInt16 / Int16</dt><dd><span id="dat-ins-u16">—</span> / <span id="dat-ins-i16">—</span></dd></div>
              <div><dt>UInt32 / Int32</dt><dd><span id="dat-ins-u32">—</span> / <span id="dat-ins-i32">—</span></dd></div>
              <div><dt>Float32</dt><dd id="dat-ins-f32">—</dd></div>
              <div><dt>UInt64 / Int64</dt><dd><span id="dat-ins-u64">—</span> / <span id="dat-ins-i64">—</span></dd></div>
              <div><dt>Float64</dt><dd id="dat-ins-f64">—</dd></div>
            </dl>
            <div class="dat-editor__inspector-help">
              <strong>Keyboard · <span id="dat-mode">HEX</span> mode</strong>
              <span>Hex: type 0–9/A–F. ASCII: click the text column and type. Tab switches modes. Shift+arrows selects a range. Ctrl/Cmd+Z/Y undo/redo.</span>
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
  const undoBtn=$('#dat-undo');
  const redoBtn=$('#dat-redo');
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
  const replaceInput=$('#dat-replace');
  const findBtn=$('#dat-find-btn');
  const replaceBtn=$('#dat-replace-btn');
  const replaceAllBtn=$('#dat-replace-all-btn');
  const bookmarkBtn=$('#dat-bookmark');
  const bookmarkSelect=$('#dat-bookmarks');
  const insertBtn=$('#dat-insert');
  const deleteBtn=$('#dat-delete');
  const endianSelect=$('#dat-endian');
  const modeLabel=$('#dat-mode');
  const insOffset=$('#dat-ins-offset');
  const insSelection=$('#dat-ins-selection');
  const insHex=$('#dat-ins-hex');
  const insAscii=$('#dat-ins-ascii');
  const insU8=$('#dat-ins-u8');
  const insI8=$('#dat-ins-i8');
  const insU16=$('#dat-ins-u16');
  const insI16=$('#dat-ins-i16');
  const insU32=$('#dat-ins-u32');
  const insI32=$('#dat-ins-i32');
  const insF32=$('#dat-ins-f32');
  const insU64=$('#dat-ins-u64');
  const insI64=$('#dat-ins-i64');
  const insF64=$('#dat-ins-f64');

  const BYTES_PER_ROW=16;
  const ROW_HEIGHT=28;
  const OVERSCAN=12;
  const MAX_FILE_SIZE=128*1024*1024;
  const MAX_HISTORY_BYTES=16*1024*1024;
  const MAX_HISTORY_STEPS=500;

  let bytes=null;
  let originalBytes=null;
  let currentName='edited.dat';
  let selectedIndex=-1;
  let anchorIndex=-1;
  let editMode='hex';
  let pendingNibble=null;
  let pendingNibbleOriginal=null;
  let pendingNibbleIndex=-1;
  let dragDepth=0;
  let renderedStart=-1;
  let renderedEnd=-1;
  let lastFindIndex=-1;
  let bookmarks=[];
  let undoStack=[];
  let redoStack=[];
  let historyBytes=0;
  let stateCounter=0;
  let currentStateId=0;
  let cleanStateId=0;

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

  function formatNumber(value){
    if(typeof value==='bigint')return value.toString();
    if(!Number.isFinite(value))return String(value);
    if(Number.isInteger(value))return String(value);
    return Number(value.toPrecision(8)).toString();
  }

  function selectionRange(){
    if(!bytes||selectedIndex<0||anchorIndex<0)return null;
    return [Math.min(anchorIndex,selectedIndex),Math.max(anchorIndex,selectedIndex)];
  }

  function selectionCount(){
    const range=selectionRange();
    return range?range[1]-range[0]+1:0;
  }

  function isDirty(){
    return pendingNibble!==null||currentStateId!==cleanStateId;
  }

  function enableControls(enabled){
    saveBtn.disabled=!enabled;
    resetBtn.disabled=!enabled;
    gotoInput.disabled=!enabled;
    gotoBtn.disabled=!enabled;
    findInput.disabled=!enabled;
    replaceInput.disabled=!enabled;
    findBtn.disabled=!enabled;
    replaceBtn.disabled=!enabled;
    replaceAllBtn.disabled=!enabled;
    bookmarkBtn.disabled=!enabled;
    bookmarkSelect.disabled=!enabled;
    insertBtn.disabled=!enabled;
    deleteBtn.disabled=!enabled;
    updateHistoryButtons();
  }

  function updateHistoryButtons(){
    undoBtn.disabled=!bytes||undoStack.length===0;
    redoBtn.disabled=!bytes||redoStack.length===0;
  }

  function updateMeta(){
    if(!bytes){
      meta.textContent='No file loaded.';
      return;
    }
    meta.textContent=`${currentName} · ${bytes.length.toLocaleString()} bytes${isDirty()?' · modified':''}`;
  }

  function captureState(){
    return {selectedIndex,anchorIndex,bookmarks:[...bookmarks]};
  }

  function restoreState(state){
    if(!state)return;
    selectedIndex=state.selectedIndex;
    anchorIndex=state.anchorIndex;
    bookmarks=[...state.bookmarks];
    pendingNibble=null;
    pendingNibbleOriginal=null;
    pendingNibbleIndex=-1;
    updateBookmarks();
  }

  function historyCost(action){
    if(action.type==='replace')return action.before.byteLength+action.after.byteLength+64;
    if(action.type==='splice')return action.removed.byteLength+action.inserted.byteLength+96;
    if(action.type==='group')return action.actions.reduce((sum,item)=>sum+historyCost(item),96);
    return 64;
  }

  function trimHistory(){
    while(undoStack.length>MAX_HISTORY_STEPS||historyBytes>MAX_HISTORY_BYTES){
      const dropped=undoStack.shift();
      if(!dropped)break;
      historyBytes=Math.max(0,historyBytes-historyCost(dropped));
    }
  }

  function pushHistory(action,stateBefore,stateAfter){
    action.stateBefore=stateBefore||captureState();
    action.stateAfter=stateAfter||captureState();
    action.beforeStateId=currentStateId;
    action.afterStateId=++stateCounter;
    currentStateId=action.afterStateId;
    undoStack.push(action);
    historyBytes+=historyCost(action);
    redoStack=[];
    trimHistory();
    updateHistoryButtons();
    updateMeta();
  }

  function spliceRaw(index,deleteCount,inserted){
    const insert=inserted instanceof Uint8Array?inserted:Uint8Array.from(inserted||[]);
    const next=new Uint8Array(bytes.length-deleteCount+insert.length);
    next.set(bytes.subarray(0,index),0);
    next.set(insert,index);
    next.set(bytes.subarray(index+deleteCount),index+insert.length);
    bytes=next;
  }

  function applyHistoryAction(action,forward){
    if(action.type==='replace'){
      bytes.set(forward?action.after:action.before,action.index);
      return;
    }
    if(action.type==='splice'){
      if(forward)spliceRaw(action.index,action.removed.length,action.inserted);
      else spliceRaw(action.index,action.inserted.length,action.removed);
      return;
    }
    if(action.type==='group'){
      const list=forward?action.actions:[...action.actions].reverse();
      for(const item of list)applyHistoryAction(item,forward);
    }
  }

  function finishMutation(message){
    syncSpacer();
    renderedStart=-1;
    renderedEnd=-1;
    renderRows(true);
    updateBookmarks();
    updateMeta();
    updateInspector();
    setStatus(message);
  }

  function undo(){
    commitPendingNibble();
    const action=undoStack.pop();
    if(!action)return;
    applyHistoryAction(action,false);
    restoreState(action.stateBefore);
    currentStateId=action.beforeStateId;
    redoStack.push(action);
    historyBytes=Math.max(0,historyBytes-historyCost(action));
    finishMutation('Undid last edit.');
    ensureVisible(selectedIndex);
    updateHistoryButtons();
  }

  function redo(){
    commitPendingNibble();
    const action=redoStack.pop();
    if(!action)return;
    applyHistoryAction(action,true);
    restoreState(action.stateAfter);
    currentStateId=action.afterStateId;
    undoStack.push(action);
    historyBytes+=historyCost(action);
    trimHistory();
    finishMutation('Redid edit.');
    ensureVisible(selectedIndex);
    updateHistoryButtons();
  }

  function readValue(size,reader){
    if(!bytes||selectedIndex<0||selectedIndex+size>bytes.length)return '—';
    try{
      const view=new DataView(bytes.buffer,bytes.byteOffset+selectedIndex,size);
      return formatNumber(reader(view,endianSelect.value==='le'));
    }catch(_){return '—';}
  }

  function updateInspector(){
    const count=selectionCount();
    if(!bytes||selectedIndex<0||selectedIndex>=bytes.length){
      for(const el of [insOffset,insSelection,insHex,insAscii,insU8,insI8,insU16,insI16,insU32,insI32,insF32,insU64,insI64,insF64])el.textContent='—';
      position.textContent='Offset —';
      return;
    }
    const value=bytes[selectedIndex];
    const range=selectionRange();
    insOffset.textContent=formatOffset(selectedIndex);
    insSelection.textContent=count>1?`${formatOffset(range[0])}–${formatOffset(range[1])} (${count.toLocaleString()} bytes)`:'1 byte';
    insHex.textContent=value.toString(16).toUpperCase().padStart(2,'0');
    insAscii.textContent=printable(value);
    insU8.textContent=String(value);
    insI8.textContent=String(value>127?value-256:value);
    insU16.textContent=readValue(2,(v,le)=>v.getUint16(0,le));
    insI16.textContent=readValue(2,(v,le)=>v.getInt16(0,le));
    insU32.textContent=readValue(4,(v,le)=>v.getUint32(0,le));
    insI32.textContent=readValue(4,(v,le)=>v.getInt32(0,le));
    insF32.textContent=readValue(4,(v,le)=>v.getFloat32(0,le));
    insU64.textContent=typeof DataView.prototype.getBigUint64==='function'?readValue(8,(v,le)=>v.getBigUint64(0,le)):'—';
    insI64.textContent=typeof DataView.prototype.getBigInt64==='function'?readValue(8,(v,le)=>v.getBigInt64(0,le)):'—';
    insF64.textContent=readValue(8,(v,le)=>v.getFloat64(0,le));
    modeLabel.textContent=editMode.toUpperCase();
    position.textContent=`Offset ${formatOffset(selectedIndex)} · ${selectedIndex.toLocaleString()} / ${(bytes.length-1).toLocaleString()}${count>1?` · ${count.toLocaleString()} selected`:''}`;
    bookmarkBtn.textContent=bookmarks.includes(selectedIndex)?'Remove bookmark':'Bookmark';
  }

  function rowCount(){
    return bytes?Math.max(1,Math.ceil(bytes.length/BYTES_PER_ROW)):0;
  }

  function syncSpacer(){
    spacer.style.height=`${rowCount()*ROW_HEIGHT}px`;
  }

  function decorateCell(el,index){
    const range=selectionRange();
    if(range&&index>=range[0]&&index<=range[1])el.classList.add('is-range');
    if(index===selectedIndex)el.classList.add('is-selected');
    if(bookmarks.includes(index))el.classList.add('is-bookmarked');
  }

  function byteCell(index,value){
    const el=document.createElement('button');
    el.type='button';
    el.className='dat-editor__byte';
    el.dataset.index=String(index);
    el.dataset.mode='hex';
    el.setAttribute('role','gridcell');
    el.setAttribute('aria-label',`Byte ${formatOffset(index)}: ${value.toString(16).padStart(2,'0')}`);
    el.textContent=value.toString(16).toUpperCase().padStart(2,'0');
    decorateCell(el,index);
    return el;
  }

  function asciiCell(index,value){
    const el=document.createElement('button');
    el.type='button';
    el.className='dat-editor__ascii-byte';
    el.dataset.index=String(index);
    el.dataset.mode='ascii';
    el.tabIndex=-1;
    el.textContent=printable(value);
    el.setAttribute('aria-label',`ASCII byte ${formatOffset(index)}: ${printable(value)}`);
    decorateCell(el,index);
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

  function setSelection(index,{scroll=true,focus=false,extend=false,mode=null}={}){
    commitPendingNibble();
    if(!bytes||!bytes.length){
      selectedIndex=-1;
      anchorIndex=-1;
      updateInspector();
      return;
    }
    const next=Math.max(0,Math.min(bytes.length-1,index));
    if(!extend||anchorIndex<0)anchorIndex=next;
    selectedIndex=next;
    if(mode)editMode=mode;
    if(scroll)ensureVisible(selectedIndex);
    renderRows(true);
    updateInspector();
    if(focus)viewport.focus({preventScroll:true});
  }

  function commitPendingNibble(){
    if(pendingNibble===null||pendingNibbleIndex<0||!bytes)return;
    const index=pendingNibbleIndex;
    const before=Uint8Array.of(pendingNibbleOriginal);
    const after=Uint8Array.of(bytes[index]);
    pendingNibble=null;
    pendingNibbleOriginal=null;
    pendingNibbleIndex=-1;
    if(before[0]!==after[0]){
      const state=captureState();
      pushHistory({type:'replace',index,before,after},state,state);
    }
    updateMeta();
  }

  function setByte(index,value,{advance=true,message=null}={}){
    if(!bytes||index<0||index>=bytes.length)return;
    commitPendingNibble();
    const old=bytes[index];
    const next=value&255;
    if(old===next){
      if(advance&&index<bytes.length-1)setSelection(index+1,{scroll:true});
      return;
    }
    const stateBefore=captureState();
    bytes[index]=next;
    if(advance&&index<bytes.length-1){selectedIndex=index+1;anchorIndex=selectedIndex;}else{selectedIndex=index;anchorIndex=index;}
    const stateAfter=captureState();
    pushHistory({type:'replace',index,before:Uint8Array.of(old),after:Uint8Array.of(next)},stateBefore,stateAfter);
    finishMutation(message||`Changed ${formatOffset(index)} to ${next.toString(16).toUpperCase().padStart(2,'0')}.`);
    ensureVisible(selectedIndex);
  }

  function adjustBookmarksForSplice(index,deleteCount,insertCount){
    const end=index+deleteCount;
    const delta=insertCount-deleteCount;
    bookmarks=bookmarks.flatMap(offset=>{
      if(deleteCount>0&&offset>=index&&offset<end)return [];
      if(offset>=end||(deleteCount===0&&offset>=index))return [offset+delta];
      return [offset];
    }).filter((value,i,array)=>value>=0&&value<bytes.length&&array.indexOf(value)===i).sort((a,b)=>a-b);
  }

  function spliceEdit(index,deleteCount,inserted,message){
    if(!bytes)return;
    commitPendingNibble();
    const at=Math.max(0,Math.min(bytes.length,index));
    const count=Math.max(0,Math.min(deleteCount,bytes.length-at));
    const insert=inserted instanceof Uint8Array?inserted:Uint8Array.from(inserted||[]);
    const stateBefore=captureState();
    const removed=bytes.slice(at,at+count);
    spliceRaw(at,count,insert);
    adjustBookmarksForSplice(at,count,insert.length);
    selectedIndex=bytes.length?Math.min(at,bytes.length-1):-1;
    anchorIndex=selectedIndex;
    const stateAfter=captureState();
    pushHistory({type:'splice',index:at,removed,inserted:insert.slice()},stateBefore,stateAfter);
    finishMutation(message);
    ensureVisible(selectedIndex);
  }

  function insertByte(index,value=0){
    spliceEdit(Math.max(0,index),0,Uint8Array.of(value&255),`Inserted ${value.toString(16).toUpperCase().padStart(2,'0')} at ${formatOffset(Math.max(0,index))}.`);
  }

  function deleteSelection(){
    if(!bytes||!bytes.length||selectedIndex<0)return;
    const range=selectionRange();
    if(!range)return;
    const count=range[1]-range[0]+1;
    spliceEdit(range[0],count,new Uint8Array(),`Deleted ${count.toLocaleString()} byte${count===1?'':'s'} at ${formatOffset(range[0])}.`);
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
      anchorIndex=selectedIndex;
      editMode='hex';
      pendingNibble=null;
      pendingNibbleOriginal=null;
      pendingNibbleIndex=-1;
      lastFindIndex=-1;
      bookmarks=[];
      undoStack=[];
      redoStack=[];
      historyBytes=0;
      currentStateId=0;
      cleanStateId=0;
      stateCounter=0;
      viewport.scrollTop=0;
      empty.hidden=true;
      enableControls(true);
      syncSpacer();
      renderedStart=-1;
      renderedEnd=-1;
      renderRows(true);
      updateBookmarks();
      updateMeta();
      updateInspector();
      setStatus(`Loaded ${currentName}. ${bytes.length.toLocaleString()} bytes ready for binary editing.`);
    }catch(error){
      setStatus(error?.message||'Failed to load file.',true);
    }
  }

  function saveFile(){
    if(!bytes)return;
    commitPendingNibble();
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
      cleanStateId=currentStateId;
      updateMeta();
      setStatus(`Saved ${currentName} · ${bytes.length.toLocaleString()} bytes.`);
    }catch(error){
      setStatus(error?.message||'Could not save file.',true);
    }
  }

  function revertFile(){
    if(!originalBytes)return;
    bytes=originalBytes.slice();
    selectedIndex=bytes.length?0:-1;
    anchorIndex=selectedIndex;
    pendingNibble=null;
    pendingNibbleOriginal=null;
    pendingNibbleIndex=-1;
    lastFindIndex=-1;
    bookmarks=[];
    undoStack=[];
    redoStack=[];
    historyBytes=0;
    currentStateId=0;
    cleanStateId=0;
    stateCounter=0;
    syncSpacer();
    renderRows(true);
    updateBookmarks();
    updateMeta();
    updateInspector();
    updateHistoryButtons();
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
    setSelection(target,{scroll:true,focus:true});
    setStatus(`Jumped to ${formatOffset(target)}.`);
  }

  function parseHexPattern(value,{allowWildcards=true}={}){
    let raw=value.trim().toUpperCase().replace(/0X/g,'').replace(/[,:;_\-]/g,' ');
    if(!raw)return null;
    let tokens;
    if(/\s/.test(raw))tokens=raw.split(/\s+/).filter(Boolean);
    else{
      if(raw.length%2)return null;
      tokens=[];
      for(let i=0;i<raw.length;i+=2)tokens.push(raw.slice(i,i+2));
    }
    const out=[];
    for(const token of tokens){
      if(allowWildcards&&token==='??'){out.push(null);continue;}
      if(!/^[0-9A-F]{2}$/.test(token))return null;
      out.push(parseInt(token,16));
    }
    return out;
  }

  function matchesAt(index,pattern){
    if(!bytes||index<0||index+pattern.length>bytes.length)return false;
    for(let j=0;j<pattern.length;j++)if(pattern[j]!==null&&bytes[index+j]!==pattern[j])return false;
    return true;
  }

  function searchPattern(pattern,from=0,to=bytes?.length||0){
    if(!bytes||!pattern?.length)return -1;
    const limit=Math.min(to,bytes.length)-pattern.length;
    for(let i=Math.max(0,from);i<=limit;i++)if(matchesAt(i,pattern))return i;
    return -1;
  }

  function findNext(){
    if(!bytes||!bytes.length)return;
    const pattern=parseHexPattern(findInput.value,{allowWildcards:true});
    if(!pattern||!pattern.length){
      setStatus('Enter hexadecimal byte pairs, e.g. DE AD BE EF. Use ?? as a wildcard byte.',true);
      return;
    }
    if(pattern.length>bytes.length){
      setStatus('Pattern is longer than the loaded file.',true);
      return;
    }
    const start=Math.max(0,lastFindIndex+1);
    let found=searchPattern(pattern,start,bytes.length);
    if(found<0&&start>0)found=searchPattern(pattern,0,start+pattern.length-1);
    if(found<0){
      setStatus('Hex pattern not found.',true);
      return;
    }
    lastFindIndex=found;
    anchorIndex=found;
    selectedIndex=Math.min(bytes.length-1,found+pattern.length-1);
    ensureVisible(found);
    renderRows(true);
    updateInspector();
    viewport.focus({preventScroll:true});
    setStatus(`Found ${pattern.length} byte${pattern.length===1?'':'s'} at ${formatOffset(found)}.`);
  }

  function parseReplacement(){
    const replacement=parseHexPattern(replaceInput.value,{allowWildcards:false});
    if(!replacement||!replacement.length){
      setStatus('Enter replacement bytes, e.g. 90 90 90 90.',true);
      return null;
    }
    return Uint8Array.from(replacement);
  }

  function replaceAt(index,replacement,message){
    const before=bytes.slice(index,index+replacement.length);
    const stateBefore=captureState();
    bytes.set(replacement,index);
    anchorIndex=index;
    selectedIndex=index+replacement.length-1;
    const stateAfter=captureState();
    pushHistory({type:'replace',index,before,after:replacement.slice()},stateBefore,stateAfter);
    lastFindIndex=index;
    finishMutation(message||`Replaced ${replacement.length} bytes at ${formatOffset(index)}.`);
    ensureVisible(index);
  }

  function replaceCurrent(){
    if(!bytes||!bytes.length)return;
    commitPendingNibble();
    const pattern=parseHexPattern(findInput.value,{allowWildcards:true});
    const replacement=parseReplacement();
    if(!pattern||!pattern.length||!replacement)return;
    if(pattern.length!==replacement.length){
      setStatus('Replace currently requires the same number of bytes as the search pattern.',true);
      return;
    }
    let index=lastFindIndex;
    if(index<0||!matchesAt(index,pattern))index=searchPattern(pattern,Math.max(0,selectedIndex),bytes.length);
    if(index<0)index=searchPattern(pattern,0,Math.max(0,selectedIndex)+pattern.length);
    if(index<0){setStatus('Hex pattern not found.',true);return;}
    replaceAt(index,replacement,`Replaced match at ${formatOffset(index)}.`);
  }

  function replaceAll(){
    if(!bytes||!bytes.length)return;
    commitPendingNibble();
    const pattern=parseHexPattern(findInput.value,{allowWildcards:true});
    const replacement=parseReplacement();
    if(!pattern||!pattern.length||!replacement)return;
    if(pattern.length!==replacement.length){
      setStatus('Replace all currently requires the same number of bytes as the search pattern.',true);
      return;
    }
    const matches=[];
    for(let i=0;i<=bytes.length-pattern.length;){
      if(matchesAt(i,pattern)){matches.push(i);i+=Math.max(1,pattern.length);}else i++;
      if(matches.length>10000){setStatus('More than 10,000 matches found. Narrow the search before replacing all.',true);return;}
    }
    if(!matches.length){setStatus('Hex pattern not found.',true);return;}
    const stateBefore=captureState();
    const actions=[];
    for(const index of matches){
      const before=bytes.slice(index,index+replacement.length);
      bytes.set(replacement,index);
      actions.push({type:'replace',index,before,after:replacement.slice()});
    }
    anchorIndex=matches[0];
    selectedIndex=matches[0]+pattern.length-1;
    lastFindIndex=matches[0];
    const stateAfter=captureState();
    pushHistory({type:'group',actions},stateBefore,stateAfter);
    finishMutation(`Replaced ${matches.length.toLocaleString()} occurrence${matches.length===1?'':'s'}.`);
    ensureVisible(matches[0]);
  }

  function updateBookmarks(){
    const current=bookmarkSelect.value;
    bookmarkSelect.replaceChildren();
    const placeholder=document.createElement('option');
    placeholder.value='';
    placeholder.textContent=bookmarks.length?`${bookmarks.length} bookmark${bookmarks.length===1?'':'s'}`:'None';
    bookmarkSelect.appendChild(placeholder);
    for(const offset of bookmarks){
      const option=document.createElement('option');
      option.value=String(offset);
      option.textContent=formatOffset(offset);
      bookmarkSelect.appendChild(option);
    }
    if(current&&bookmarks.includes(Number(current)))bookmarkSelect.value=current;
    bookmarkBtn.textContent=bookmarks.includes(selectedIndex)?'Remove bookmark':'Bookmark';
  }

  function toggleBookmark(){
    if(!bytes||selectedIndex<0)return;
    const at=bookmarks.indexOf(selectedIndex);
    if(at>=0){
      bookmarks.splice(at,1);
      setStatus(`Removed bookmark at ${formatOffset(selectedIndex)}.`);
    }else{
      bookmarks.push(selectedIndex);
      bookmarks.sort((a,b)=>a-b);
      setStatus(`Bookmarked ${formatOffset(selectedIndex)}.`);
    }
    updateBookmarks();
    renderRows(true);
  }

  function handleHexKey(key){
    if(!bytes||selectedIndex<0||!/^[0-9a-f]$/i.test(key))return false;
    const nibble=parseInt(key,16);
    if(pendingNibble===null||pendingNibbleIndex!==selectedIndex){
      commitPendingNibble();
      pendingNibble=nibble;
      pendingNibbleIndex=selectedIndex;
      pendingNibbleOriginal=bytes[selectedIndex];
      bytes[selectedIndex]=(nibble<<4)|(bytes[selectedIndex]&0x0F);
      updateMeta();
      renderRows(true);
      updateInspector();
      setStatus(`Editing ${formatOffset(selectedIndex)}…`);
    }else{
      const index=selectedIndex;
      bytes[index]=(pendingNibble<<4)|nibble;
      const before=Uint8Array.of(pendingNibbleOriginal);
      const after=Uint8Array.of(bytes[index]);
      pendingNibble=null;
      pendingNibbleOriginal=null;
      pendingNibbleIndex=-1;
      const stateBefore=captureState();
      if(index<bytes.length-1){selectedIndex=index+1;anchorIndex=selectedIndex;}
      const stateAfter=captureState();
      if(before[0]!==after[0])pushHistory({type:'replace',index,before,after},stateBefore,stateAfter);
      finishMutation(`Changed ${formatOffset(index)} to ${after[0].toString(16).toUpperCase().padStart(2,'0')}.`);
      ensureVisible(selectedIndex);
    }
    return true;
  }

  function handleAsciiKey(event){
    if(!bytes||selectedIndex<0||event.ctrlKey||event.metaKey||event.altKey||event.key.length!==1)return false;
    const code=event.key.charCodeAt(0);
    if(code>255)return false;
    setByte(selectedIndex,code,{advance:true,message:`Wrote ${printable(code)} at ${formatOffset(selectedIndex)}.`});
    return true;
  }

  function handleViewportKeydown(event){
    if(!bytes||selectedIndex<0)return;
    const modifier=event.ctrlKey||event.metaKey;
    if(modifier&&!event.altKey){
      const key=event.key.toLowerCase();
      if(key==='z'){
        event.preventDefault();
        if(event.shiftKey)redo();else undo();
        return;
      }
      if(key==='y'){
        event.preventDefault();
        redo();
        return;
      }
      if(key==='a'){
        event.preventDefault();
        commitPendingNibble();
        anchorIndex=0;
        selectedIndex=bytes.length-1;
        renderRows(true);
        updateInspector();
        setStatus(`Selected all ${bytes.length.toLocaleString()} bytes.`);
        return;
      }
    }
    if(event.key==='Tab'){
      event.preventDefault();
      commitPendingNibble();
      editMode=editMode==='hex'?'ascii':'hex';
      updateInspector();
      setStatus(`${editMode.toUpperCase()} editing mode.`);
      return;
    }
    if(editMode==='hex'&&handleHexKey(event.key)){
      event.preventDefault();
      return;
    }
    if(editMode==='ascii'&&handleAsciiKey(event)){
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
      case 'Home':target=event.ctrlKey||event.metaKey?0:Math.floor(selectedIndex/BYTES_PER_ROW)*BYTES_PER_ROW;break;
      case 'End':target=event.ctrlKey||event.metaKey?bytes.length-1:Math.min(bytes.length-1,Math.floor(selectedIndex/BYTES_PER_ROW)*BYTES_PER_ROW+15);break;
      case 'Delete':deleteSelection();event.preventDefault();return;
      case 'Backspace':
        if(selectionCount()>1)deleteSelection();
        else if(selectedIndex>0){anchorIndex=selectedIndex-1;selectedIndex=selectedIndex-1;deleteSelection();}
        event.preventDefault();return;
      case 'Insert':insertByte(selectionRange()?.[0]??selectedIndex,0);event.preventDefault();return;
      case 'Escape':
        event.preventDefault();
        anchorIndex=selectedIndex;
        renderRows(true);
        updateInspector();
        return;
      default:return;
    }
    event.preventDefault();
    setSelection(target,{scroll:true,extend:event.shiftKey});
  }

  openBtn.addEventListener('click',()=>input.click());
  input.addEventListener('change',()=>{
    const file=input.files?.[0];
    if(file)loadFile(file);
    input.value='';
  });
  saveBtn.addEventListener('click',saveFile);
  undoBtn.addEventListener('click',undo);
  redoBtn.addEventListener('click',redo);
  resetBtn.addEventListener('click',revertFile);
  gotoBtn.addEventListener('click',goToOffset);
  gotoInput.addEventListener('keydown',e=>{if(e.key==='Enter'){e.preventDefault();goToOffset();}});
  findBtn.addEventListener('click',findNext);
  findInput.addEventListener('keydown',e=>{if(e.key==='Enter'){e.preventDefault();findNext();}});
  replaceBtn.addEventListener('click',replaceCurrent);
  replaceAllBtn.addEventListener('click',replaceAll);
  bookmarkBtn.addEventListener('click',toggleBookmark);
  bookmarkSelect.addEventListener('change',()=>{
    if(bookmarkSelect.value==='')return;
    const target=Number(bookmarkSelect.value);
    if(Number.isInteger(target)){
      setSelection(target,{scroll:true,focus:true});
      setStatus(`Jumped to bookmark ${formatOffset(target)}.`);
    }
    bookmarkSelect.value='';
  });
  insertBtn.addEventListener('click',()=>insertByte(selectionRange()?.[0]??(bytes?.length||0),0));
  deleteBtn.addEventListener('click',deleteSelection);
  endianSelect.addEventListener('change',()=>updateInspector());

  viewport.addEventListener('scroll',()=>renderRows(false),{passive:true});
  viewport.addEventListener('keydown',handleViewportKeydown);
  viewport.addEventListener('click',event=>{
    const target=event.target.closest('[data-index]');
    if(!target||!viewport.contains(target))return;
    const index=Number(target.dataset.index);
    if(Number.isInteger(index))setSelection(index,{scroll:false,focus:true,extend:event.shiftKey,mode:target.dataset.mode||'hex'});
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
