// Editable JSCAD parametric old port. Coordinates are glTF/Godot Y-up, metres.
// Run: node tools/old_port/build_port.cjs
const fs = require('fs');
const path = require('path');
const j = require('@jscad/modeling');
const {cuboid, cylinder, cylinderElliptic, ellipsoid, polyhedron} = j.primitives;
const {translate, rotateX, rotateY, rotateZ, scale} = j.transforms;
const {geom3} = j.geometries;
const OUT = path.resolve(__dirname, '../../assets/old_port');
fs.mkdirSync(OUT,{recursive:true});
let seed=7261;
const rnd=()=>{seed=(Math.imul(seed,1664525)+1013904223)>>>0;return seed/4294967296;};
const H=(x,z)=>Math.sin(x*.035)*1.8+Math.cos(z*.038)*2.2+7*Math.exp(-((x-42)**2+(z+15)**2)/2200);
const colors={stone:'#a6b4aa',stone2:'#829a94',stone3:'#667f80',rock:'#81979c',rock2:'#9eaaa4',rock3:'#5c757d',seam:'#c0bc9e',turf:'#80b94f',turf2:'#a0c857',turf3:'#619c45',wood:'#62452e',woodlight:'#a17a48',bark:'#695442',barklight:'#886e47',leaf:'#78a945',leaf2:'#a4c45c',leaf3:'#588c3e',leaf4:'#b5cf6a',plaster:'#e5dab2',cream:'#fff0cd',roof:'#9a4d39',roof2:'#b76744',roof3:'#ce8052',glass:'#365d60',dark:'#293f45',water:'#57b7b9',shallows:'#82d0c1',foam:'#cee9c4',sand:'#d7c994',flower:'#d8a9cf',pink:'#e9b5d4',lavender:'#a9a4d5',yellow:'#f4d588',metal:'#a89b72'};
let shapes=[];
const add=(mat,g)=>shapes.push({mat,g});
function box(mat,p,s,ry=0,rz=0){add(mat,translate(p,rotateY(ry,rotateZ(rz,cuboid({size:s})))));}
function cyl(mat,p,r,h,top=r,n=12){add(mat,translate(p,rotateX(-Math.PI/2,cylinderElliptic({height:h,segments:n,startRadius:[r,r],endRadius:[top,top]}))));}
function ball(mat,p,s,n=12){add(mat,translate(p,ellipsoid({radius:s,segments:n})));}
function beam(mat,a,b,r=.12,r2=r,n=8){
 const v=b.map((x,i)=>x-a[i]),len=Math.hypot(...v),yaw=Math.atan2(v[0],v[2]),pitch=Math.acos(v[1]/len);
 let g=rotateX(-Math.PI/2,cylinderElliptic({height:len,segments:n,startRadius:[r,r],endRadius:[r2,r2]}));
 g=rotateY(yaw,rotateX(pitch,g));add(mat,translate(a.map((x,i)=>(x+b[i])/2),g));
}
function tri(mat,a,b,c){add(mat,geom3.fromPoints([[a,b,c]]));}
function quad(mat,a,b,c,d){tri(mat,a,b,c);tri(mat,a,c,d);}
function ringCliff(cx,cz,rx,rz,bottom,top,phase=0){
 const n=36,levels=7,rings=[];
 let jitter=Array.from({length:n},()=>.88+rnd()*.21);
 for(let l=0;l<levels;l++){
  let t=l/(levels-1),ring=[];
  for(let i=0;i<n;i++){
   let a=i*Math.PI*2/n,rad=jitter[i]*(.83+.17*t+.025*Math.sin(i*3.7+l*1.4));
   ring.push([cx+Math.cos(a)*rx*rad, bottom+(top-bottom)*t+(t>.01?Math.sin(i*2.4+phase)*1.0:0),cz+Math.sin(a)*rz*rad]);
  }rings.push(ring);
 }
 for(let l=0;l<levels-1;l++)for(let i=0;i<n;i++){
  let k=(i+1)%n,mat=['rock3','rock','rock2','rock','seam','rock2'][l];
  quad(mat,rings[l][k],rings[l][i],rings[l+1][i],rings[l+1][k]);
  if(l>1&&i%5===0)beam('rock3',rings[l][i],rings[l+1][i],.10,.07,5);
 }
 let rim=rings[levels-1],center=[cx,top+.35,cz];
 for(let i=0;i<n;i++){
  let k=(i+1)%n,a=rim[i],b=rim[k],aa=[a[0],a[1]+.35,a[2]],bb=[b[0],b[1]+.35,b[2]];
  quad('turf3',b,a,aa,bb);tri(i%4===0?'turf2':'turf',center,bb,aa);
 }
}
function roof(p,w,d,h){
 const [x,y,z]=p;
 const pts=[[-w/2,0,-d/2],[w/2,0,-d/2],[0,h,-d/2],[-w/2,0,d/2],[w/2,0,d/2],[0,h,d/2]];
 add('roof',translate(p,polyhedron({points:pts,faces:[[0,2,1],[3,4,5],[0,3,5,2],[1,2,5,4],[0,1,4,3]],orientation:'outward'})));
 // Individual overlapping terracotta tiles, both slopes.
 for(let side of [-1,1])for(let r=0;r<6;r++)for(let k=0;k<10;k++){
  let t=(r+.5)/6,tx=side*(w/2)*(1-t),ty=h*t+.06,tz=-d/2+(k+.5)*d/10;
  box(['roof','roof2','roof3'][(r+k)%3],[x+tx,y+ty,z+tz],[Math.hypot(w/2,h)/6+.09,.10,d/10-.035],0,-side*Math.atan2(h,w/2));
 }
 beam('cream',[x,y+h+.1,z-d/2-.12],[x,y+h+.1,z+d/2+.12],.13,.13);
}
function house(){
 box('stone',[0,.32,0],[8.1,.64,7.1]);box('plaster',[0,2.7,0],[7.6,4.8,6.7]);
 for(let x of [-3.82,0,3.82])box('wood',[x,2.7,3.4],[.18,4.9,.16]);
 for(let y of [.8,3.3,4.9])box('wood',[0,y,3.4],[7.8,.19,.17]);
 for(let z of [-3.4,0,3.4])box('wood',[3.84,2.7,z],[.18,4.9,.18]);
 for(let x of [-2.45,2.45]){
  box('woodlight',[x,2.55,3.5],[1.54,1.94,.16]);box('glass',[x,2.55,3.6],[1.21,1.61,.1]);
  box('cream',[x,2.55,3.68],[.08,1.64,.08]);box('cream',[x,2.55,3.68],[1.25,.09,.08]);
  for(let s of [-1,1]){box('wood',[x+s*.9,2.55,3.49],[.36,1.8,.1]);for(let yy of [2,2.3,2.6,2.9,3.2])box('woodlight',[x+s*.9,yy,3.57],[.32,.06,.06]);}
  box('wood',[x,1.48,3.7],[1.7,.2,.6]);
  for(let f=0;f<5;f++){ball('leaf',[x-.6+f*.3,1.7,3.7],[.22,.17,.23],8);ball(f%2?'yellow':'pink',[x-.6+f*.3,1.86,3.72],[.1,.1,.1],8);}
 }
 box('wood',[0,1.5,3.51],[1.35,2.8,.18]);for(let x of [-.48,-.24,0,.24,.48])box('woodlight',[x,1.5,3.63],[.025,2.6,.06]);
 ball('metal',[.43,1.45,3.72],[.08,.08,.08],8);box('stone',[0,.3,3.95],[2.1,.3,1]);
 roof([0,5.1,0],8.8,7.8,2.8);box('stone2',[2,7,-1.6],[.85,2.8,.9]);box('stone',[2,8.43,-1.6],[1.12,.24,1.12]);
}
function windmill(){
 cyl('stone',[0,.3,0],2.9,.6,2.9,20);cyl('plaster',[0,4.2,0],2.15,7.8,1.5,16);
 for(let a=0;a<8;a++){let t=a*Math.PI/4;beam('wood',[Math.sin(t)*2.14,.7,Math.cos(t)*2.14],[Math.sin(t)*1.53,7.7,Math.cos(t)*1.53],.15,.11);}
 for(let y of [1.9,4.5,7.6])cyl('woodlight',[0,y,0],2.26-y*.085,.16,2.26-y*.085,16);
 box('wood',[0,1.75,2.07],[1.2,2.6,.18]);box('woodlight',[0,1.75,2.2],[.05,2.5,.08]);
 for(let x of [-1,1]){box('woodlight',[x,5.5,1.65],[.65,.95,.16]);box('glass',[x,5.5,1.76],[.46,.7,.08]);}
 cyl('wood',[0,7.3,0],2.8,.4,2.8,20);
 for(let a=0;a<16;a++){let t=a*Math.PI/8;beam('woodlight',[Math.sin(t)*2.65,7.5,Math.cos(t)*2.65],[Math.sin(t)*2.65,8.2,Math.cos(t)*2.65],.06,.06,6);}
 cyl('roof',[0,8.5,0],2.6,2.6,.05,20);
 // Conical roof has distinct overlapping shingle rows.
 for(let r=0;r<5;r++)for(let i=0;i<20;i++){
  let t=i*Math.PI/10,rad=2.52-r*.44,y=7.35+r*.48;
  box(r%2?'roof2':'roof3',[Math.sin(t)*rad,y,Math.cos(t)*rad],[rad*.30,.14,.55],t,0);
 }
 beam('wood',[0,7.7,.9],[0,7.7,2.7],.32,.32,12);
 const angle=.32,cy=7.7,cz=2.8;
 function rotorPoint(x,y,z=0){return [x*Math.cos(angle)-y*Math.sin(angle),cy+x*Math.sin(angle)+y*Math.cos(angle),cz+z];}
 for(let i=0;i<4;i++){
  let a=i*Math.PI/2;const pp=(x,y,z=0)=>rotorPoint(x*Math.cos(a)-y*Math.sin(a),x*Math.sin(a)+y*Math.cos(a),z);
  beam('wood',pp(0,.2),pp(0,7),.16,.09);
  for(let x of [.22,1.55])beam('woodlight',pp(x,2.2),pp(x,6.9),.07,.07,6);
  for(let y=2.2;y<7;y+=.49)beam('woodlight',pp(.2,y),pp(1.58,y),.055,.055,6);
  for(let x=.45;x<1.55;x+=.34)beam('woodlight',pp(x,2.2),pp(x,6.9),.035,.035,5);
  // Partial cream sail canvas leaves the lattice visible through open cells.
  for(let y=2.3;y<6.8;y+=.98)quad('cream',pp(.24,y,.045),pp(1.5,y,.045),pp(1.5,y+.45,.045),pp(.24,y+.45,.045));
 }
 ball('metal',[0,cy,cz+.12],[.38,.38,.25],12);
 // Timber gantry, deck and diagonal braces beside the tower.
 for(let x of [-3.1,3.1])for(let z of [-2,2]){beam('wood',[x,0,z],[x,3.5,z],.16,.12);beam('wood',[x,0,z],[x*.7,3.3,-z],.10,.10);}
 for(let k=0;k<15;k++)box('woodlight',[-3+k*.43,3.35,0],[.39,.18,4.3]);
}
function tree(big=false){
 const s=big?1.9:1;
 const P=p=>p.map(v=>v*s);
 for(let i=0;i<7;i++){let a=i*Math.PI*2/7;beam('bark',P([Math.sin(a)*2.2,.1,Math.cos(a)*2.2]),P([Math.sin(a)*.35,2,Math.cos(a)*.35]),.29*s,.48*s);}
 beam('bark',P([0,.2,0]),P([-.3,4,0]),.76*s,.52*s,12);beam('barklight',P([-.3,3.5,0]),P([.45,6.7,.2]),.52*s,.3*s,10);
 for(let i=0;i<9;i++){
  let a=i*2.39996,rad=2.7+(i%3)*.5,tip=[Math.cos(a)*rad,6.2+(i%3)*.7,Math.sin(a)*rad];
  let elbow=[tip[0]*.5,4.9+(i%2)*.6,tip[2]*.45];
  beam('bark',P([-.1,3.7,0]),P(elbow),.3*s,.21*s,9);beam('barklight',P(elbow),P(tip),.21*s,.07*s,8);
  for(let k=0;k<4;k++){
   let p=[tip[0]+Math.cos(k*1.7+i)*1.1,tip[1]+.3+(k%2)*.8,tip[2]+Math.sin(k*1.7+i)*1.1];
   ball(['leaf','leaf2','leaf3','leaf4'][(i+k)%4],P(p),[1.55*s,(.85+rnd()*.35)*s,1.4*s],12);
  }
 }
 for(let k=0;k<7;k++)ball(k%2?'leaf2':'leaf',P([Math.cos(k*2.4)*1.4,8.1+(k%2)*.5,Math.sin(k*2.4)*1.3]),[1.7*s,1.1*s,1.55*s],12);
}
function at(fn,p,s=1,ry=0){let start=shapes.length;fn();for(let i=start;i<shapes.length;i++)shapes[i].g=translate(p,rotateY(ry,scale([s,s,s],shapes[i].g)));}
function ribbon(mat,points,width,yoffset=0){for(let i=0;i<points.length-1;i++){
 let a=points[i],b=points[i+1],d=[b[0]-a[0],b[1]-a[1]],len=Math.hypot(...d),sx=-d[1]/len*width/2,sz=d[0]/len*width/2;
 const p=(x,z)=>[x,H(x,z)+yoffset,z];quad(mat,p(a[0]-sx,a[1]-sz),p(b[0]-sx,b[1]-sz),p(b[0]+sx,b[1]+sz),p(a[0]+sx,a[1]+sz));
}}
function landscape(){
 // Irregular skyline ridges, authored as angular rock masses rather than cones.
 for(let i=0;i<9;i++)ringCliff(-240+i*62,-235+(i%3)*13,48,30,-9,27+Math.sin(i*2.1)*13,i);
 ringCliff(-124,-43,23,78,-8,30,2);ringCliff(141,-24,31,88,-8,39,5);
 ringCliff(-106,68,20,29,-8,21,8);ringCliff(120,107,28,20,-8,15,3);
 ringCliff(25,-154,78,28,-8,10,4);
 // Curving water body: rings of shallows/foam/shore follow the physical terrain.
 const n=112,cx=78,cz=74,rx=52,rz=34,shore=[];
 function lp(a,s){let w=1+.065*Math.sin(3*a)+.035*Math.sin(7*a);return [cx+Math.cos(a)*rx*w*s,cz+Math.sin(a)*rz*w*s];}
 const center=[cx,H(cx,cz)+.15,cz];
 for(let i=0;i<n;i++){
  let a=i*2*Math.PI/n,b=(i+1)*2*Math.PI/n;
  let pa=lp(a,.90),pb=lp(b,.9),qa=lp(a,1),qb=lp(b,1),sa=lp(a,1.055),sb=lp(b,1.055);
  const v=p=>[p[0],H(...p)+.27,p[1]];
  for(let ring=0;ring<24;ring++){
   let ia=lp(a,ring*.9/24),ib=lp(b,ring*.9/24),oa=lp(a,(ring+1)*.9/24),ob=lp(b,(ring+1)*.9/24);
   if(ring===0)tri('water',v(ia),v(ob),v(oa));else quad('water',v(ia),v(ib),v(ob),v(oa));
  }
  quad('shallows',v(pa),v(pb),v(qb),v(qa));quad('sand',v(qa),v(qb),v(sb),v(sa));
  if(i%3!==0){let fa=lp(a,.985),fb=lp(b,.985);quad('foam',v(fa),v(fb),v(qb),v(qa));}
  if(i%5===0){let p=lp(a,1.04);ball(i%2?'stone2':'stone',[p[0],H(...p)+.35,p[1]],[.7+rnd()*.6,.35,.6],8);}
 }
 // Terrace contours and rows of lavender, pink and cream flowers.
 for(let row=0;row<15;row++){
  let points=[];
  for(let k=0;k<=28;k++){let x=-72+k*2.45,z=36+row*1.50+4*Math.sin(k*.09+row*.025);points.push([x,z]);}
  ribbon(row%3===0?'sand':'turf2',points,.75,.12);
  for(let k=0;k<66;k++){
   let x=-72+k*1.04,z=36+row*1.50+4*Math.sin(k*.038+row*.025),y=H(x,z)+.27;
   // Crossed leaves and clustered flower heads form readable planted rows.
   beam('leaf3',[x,y-.12,z],[x,y+.45,z],.028,.024,5);
   const col=['lavender','pink','yellow'][row%3];
   for(let f=0;f<3;f++)ball(col,[x+(f-1)*.13,y+.39+(f%2)*.12,z],[.14,.18,.14],6);
  }
 }
 for(let p of [[-71,35,1.05],[-29,59,.82],[8,43,.72]])at(windmill,[p[0],H(p[0],p[1]),p[1]],p[2]);
 for(let p of [[-61,20,.7,.1],[-41,28,.62,-.2],[7,26,.65,.3],[33,42,.6,.6]])at(house,[p[0],H(p[0],p[1]),p[1]],p[2],p[3]);
 at(()=>tree(true),[-82,H(-82,5),5]);
 for(let p of [[-112,-13,1],[-98,37,.9],[97,29,1.1],[124,8,1.2],[102,-48,.9],[-70,-105,.8]])at(tree,[p[0],H(p[0],p[1]),p[1]],p[2]);
 // Stone quay, timber pier, posts, fishing crates and mooring bollards.
 for(let k=0;k<26;k++)box('woodlight',[37+k*.58,H(37,73)+.65,73],[.54,.22,3]);
 for(let x of [37,43,49])for(let z of [71.5,74.5]){cyl('wood',[x,H(37,73)+.25,z],.18,2);cyl('metal',[x,H(37,73)+1.3,z],.25,.22);}
 for(let p of [[36,70],[38,69],[39,71]]){box('wood',[p[0],H(...p)+.7,p[1]],[1.1,1.1,1]);for(let y of [.4,.9])box('woodlight',[p[0],H(...p)+y,p[1]+.52],[1.15,.1,.07]);}
 city();
}
function tower(x,z,y=10,h=13){
 cyl('stone',[x,y+h/2,z],3.5,h,3.15,16);cyl('stone2',[x,y+h-1,z],3.65,.5,3.65,16);
 cyl('roof',[x,y+h+2.3,z],4.0,4.6,.1,16);
 for(let a=0;a<8;a++){let t=a*Math.PI/4;box('stone',[x+Math.sin(t)*3.25,y+h+.2,z+Math.cos(t)*3.25],[.9,1.4,.9],t);}
 box('dark',[x,y+h*.66,z+3.32],[.65,2,.12]);
}
function city(){
 const y=10;
 for(let i=0;i<28;i++){
  let x=-42+i*4.7,z=-135+4*Math.sin(i*.16);
  box(i%3?'stone':'stone2',[x,y+4.5,z],[4.7,9,2.6]);box('cream',[x,y+8.7,z],[4.7,.35,3]);
  for(let k=0;k<3;k++)box('stone',[x-1.6+k*1.6,y+9.6,z],[.9,1.6,2.6]);
  if(i%6===0)tower(x,z,y,12+(i%3));
 }
 // Gatehouse and recessed dark arch (jambs + keystone profile).
 box('dark',[12,13.7,-131],[5,7.4,.3]);
 for(let x of [8.7,15.3])box('stone',[x,14,-130],[1.7,8,4]);box('stone',[12,18.7,-130],[8.5,2,4]);
 for(let i=0;i<7;i++){let a=i*Math.PI/6;box('cream',[12+Math.cos(a)*2.5,15.1+Math.sin(a)*2.5,-127.8],[.8,.8,.6],0,a);}
 tower(5,-132,y,15);tower(19,-132,y,15);
 for(let i=0;i<22;i++){
  let x=-36+(i%8)*12,z=-149-Math.floor(i/8)*12,s=.6+(i%3)*.09;
  at(house,[x,y,z],s,(i%2)*.15);
 }
 // Cathedral: buttressed nave, tracery, twin spires and flying buttresses.
 const cx=46,cz=-172;
 box('stone',[cx,y+11,cz],[14,22,27]);roof([cx,y+22,cz],17,30,10);
 for(let side of [-1,1])for(let k=0;k<5;k++){
  let z=cz-11+k*5.5;box('cream',[cx+side*7.4,y+10,z],[1.1,20,1.1]);
  box('glass',[cx+side*7.1,y+13,z+2.4],[.18,7,2.5]);
  beam('stone',[cx+side*8,y+19,z],[cx+side*12,y+7,z],.55,.55);box('stone',[cx+side*12,y+3.5,z],[1.6,7,2]);
 }
 for(let x of [cx-6,cx+6]){
  box('stone',[x,y+18,cz+16],[5,36,5]);
  for(let yy of [y+12,y+25,y+34])box('cream',[x,yy,cz+16],[5.5,.45,5.5]);
  cyl('roof',[x,y+43,cz+16],3.8,18,0,8);
  for(let s of [-1,1]){box('glass',[x+s*1.05,y+29,cz+18.56],[.65,4.5,.15]);}
  beam('metal',[x,y+52,cz+16],[x,y+55,cz+16],.1,.1);beam('metal',[x-.9,y+54,cz+16],[x+.9,y+54,cz+16],.08,.08);
 }
 cyl('cream',[cx,y+18,cz+13.7],2.8,.2,2.8,20); // rose window turned onto facade
 let last=shapes.pop();last.g=translate([cx,y+18,cz+13.7],rotateX(Math.PI/2,translate([-cx,-y-18,-cz-13.7],last.g)));shapes.push(last);
 for(let i=0;i<12;i++){let a=i*Math.PI/6;beam('glass',[cx,y+18,cz+13.87],[cx+Math.cos(a)*2.4,y+18+Math.sin(a)*2.4,cz+13.87],.10,.10,5);}
}
function exportGLB(name,fn){
 shapes=[];let start=Date.now();fn();
 const groups=new Map();
 for(let {mat,g} of shapes){
  if(!groups.has(mat))groups.set(mat,[]);let out=groups.get(mat);
  for(let poly of geom3.toPolygons(g)){
   let vs=poly.vertices;
   for(let i=1;i<vs.length-1;i++){
    let a=vs[0],b=vs[i],c=vs[i+1];
    let u=b.map((v,k)=>v-a[k]),v=c.map((w,k)=>w-a[k]),n=[u[1]*v[2]-u[2]*v[1],u[2]*v[0]-u[0]*v[2],u[0]*v[1]-u[1]*v[0]],len=Math.hypot(...n);
    if(len<1e-9)continue;n=n.map(v=>v/len);
    for(let p of [a,b,c])out.push(...p,...n);
   }
  }
 }
 const json={asset:{version:'2.0',generator:'JSCAD @jscad/modeling '+require('@jscad/modeling/package.json').version},scene:0,scenes:[{nodes:[0]}],nodes:[{name,mesh:0}],meshes:[{name,primitives:[]}],materials:[],buffers:[{byteLength:0}],bufferViews:[],accessors:[]};
 let bins=[],offset=0,total=0;
 for(let [mat,data] of groups){
  let buf=Buffer.from(new Float32Array(data).buffer),count=data.length/6,mins=[Infinity,Infinity,Infinity],maxs=[-Infinity,-Infinity,-Infinity];
  for(let k=0;k<data.length;k+=6)for(let a=0;a<3;a++){mins[a]=Math.min(mins[a],data[k+a]);maxs[a]=Math.max(maxs[a],data[k+a]);}
  const view=json.bufferViews.length,acc=json.accessors.length,mi=json.materials.length;
  json.bufferViews.push({buffer:0,byteOffset:offset,byteLength:buf.length,byteStride:24,target:34962});
  json.accessors.push({bufferView:view,byteOffset:0,componentType:5126,count,type:'VEC3',min:mins,max:maxs},{bufferView:view,byteOffset:12,componentType:5126,count,type:'VEC3'});
  let hex=colors[mat].slice(1);let rgb=[0,2,4].map(i=>parseInt(hex.slice(i,i+2),16)/255);
  // glTF color factors are linear. Convert display sRGB palette to linear.
  rgb=rgb.map(c=>c<=.04045?c/12.92:((c+.055)/1.055)**2.4);
  json.materials.push({name:mat,pbrMetallicRoughness:{baseColorFactor:[...rgb,1],metallicFactor:0,roughnessFactor:.92},doubleSided:true});
  json.meshes[0].primitives.push({attributes:{POSITION:acc,NORMAL:acc+1},material:mi,mode:4});
  bins.push(buf);offset+=buf.length;total+=count/3;
 }
 json.buffers[0].byteLength=offset;
 let jb=Buffer.from(JSON.stringify(json)),pad=(4-jb.length%4)%4;jb=Buffer.concat([jb,Buffer.alloc(pad,32)]);let bin=Buffer.concat(bins);
 let header=Buffer.alloc(12),jh=Buffer.alloc(8),bh=Buffer.alloc(8);header.writeUInt32LE(0x46546c67,0);header.writeUInt32LE(2,4);header.writeUInt32LE(12+8+jb.length+8+bin.length,8);jh.writeUInt32LE(jb.length);jh.writeUInt32LE(0x4e4f534a,4);bh.writeUInt32LE(bin.length);bh.writeUInt32LE(0x004e4942,4);
 let result=Buffer.concat([header,jh,jb,bh,bin]);fs.writeFileSync(path.join(OUT,name+'.glb'),result);
 let stats={name,triangles:total,materials:groups.size,bytes:result.length,jscadSolids:shapes.length,buildMs:Date.now()-start};console.log(JSON.stringify(stats));return stats;
}
const stats=[exportGLB('port_house',house),exportGLB('port_windmill',windmill),exportGLB('port_tree',tree),exportGLB('port_landscape',landscape)];
fs.writeFileSync(path.join(OUT,'build_manifest.json'),JSON.stringify({tool:'JSCAD @jscad/modeling',version:require('@jscad/modeling/package.json').version,node:process.version,source:'tools/old_port/build_port.cjs',units:'metres, Y up',assets:stats},null,2));

