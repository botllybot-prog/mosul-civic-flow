import { useEffect, useRef } from 'react';
import SignaturePad from 'signature_pad';
import { Button } from '@/components/ui/button';
import { Eraser, Check } from 'lucide-react';
export function SignatureCanvas({onSave}:{onSave:(image:string)=>void}) {
 const canvas = useRef<HTMLCanvasElement>(null); const pad = useRef<SignaturePad | null>(null);
 useEffect(()=>{const element=canvas.current;if(!element)return;const ratio=Math.max(window.devicePixelRatio||1,1);element.width=element.clientWidth*ratio;element.height=element.clientHeight*ratio;element.getContext('2d')?.scale(ratio,ratio);pad.current=new SignaturePad(element,{penColor:getComputedStyle(document.documentElement).getPropertyValue('--foreground').trim()});return ()=>pad.current?.off();},[]);
 return <div><canvas ref={canvas} width={800} height={300} className="signature-canvas" aria-label="مساحة التوقيع المباشر"/><div className="mt-4 flex justify-between"><Button variant="outline" onClick={()=>pad.current?.clear()}><Eraser/>مسح</Button><Button onClick={()=>{if(pad.current && !pad.current.isEmpty())onSave(pad.current.toDataURL());}}><Check/>اعتماد التوقيع</Button></div></div>;
}
