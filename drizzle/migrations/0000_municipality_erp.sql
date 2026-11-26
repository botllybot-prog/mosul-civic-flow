CREATE TYPE public.app_role AS ENUM ('admin','sector_manager','employee');
CREATE TABLE public.user_roles(id uuid PRIMARY KEY DEFAULT gen_random_uuid(),user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,role public.app_role NOT NULL,sector_id uuid,UNIQUE(user_id,role));
GRANT SELECT ON public.user_roles TO authenticated; GRANT ALL ON public.user_roles TO service_role;
ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;
CREATE POLICY own_role ON public.user_roles FOR SELECT TO authenticated USING(user_id=auth.uid());
CREATE FUNCTION public.has_role(_user_id uuid,_role public.app_role) RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path=public AS $$ SELECT EXISTS(SELECT 1 FROM public.user_roles WHERE user_id=_user_id AND role=_role) $$;
CREATE TABLE public.erp_records(id uuid PRIMARY KEY DEFAULT gen_random_uuid(),kind text NOT NULL CHECK(kind IN('sector','department','employee','book','vehicle')),name text NOT NULL,sector_id uuid,payload jsonb NOT NULL DEFAULT '{}',created_at timestamptz NOT NULL DEFAULT now());
GRANT SELECT,INSERT,UPDATE,DELETE ON public.erp_records TO authenticated; GRANT ALL ON public.erp_records TO service_role;
ALTER TABLE public.erp_records ENABLE ROW LEVEL SECURITY;
CREATE POLICY municipal_read ON public.erp_records FOR SELECT TO authenticated USING(EXISTS(SELECT 1 FROM public.user_roles WHERE user_id=auth.uid()));
CREATE POLICY director_write ON public.erp_records FOR ALL TO authenticated USING(public.has_role(auth.uid(),'admin')) WITH CHECK(public.has_role(auth.uid(),'admin'));
CREATE POLICY sector_department_write ON public.erp_records FOR ALL TO authenticated USING(kind='department' AND EXISTS(SELECT 1 FROM public.user_roles r WHERE r.user_id=auth.uid() AND r.role='sector_manager' AND r.sector_id=erp_records.sector_id)) WITH CHECK(kind='department' AND EXISTS(SELECT 1 FROM public.user_roles r WHERE r.user_id=auth.uid() AND r.role='sector_manager' AND r.sector_id=erp_records.sector_id));
CREATE TABLE public.book_movements(id uuid PRIMARY KEY DEFAULT gen_random_uuid(),book_id uuid REFERENCES public.erp_records(id) ON DELETE CASCADE NOT NULL,department text NOT NULL,entered_at timestamptz NOT NULL DEFAULT now(),left_at timestamptz,actor_id uuid);
GRANT SELECT ON public.book_movements TO authenticated; GRANT ALL ON public.book_movements TO service_role;
ALTER TABLE public.book_movements ENABLE ROW LEVEL SECURITY;
CREATE POLICY movements_read ON public.book_movements FOR SELECT TO authenticated USING(EXISTS(SELECT 1 FROM public.user_roles WHERE user_id=auth.uid()));
CREATE FUNCTION public.route_book(_book_id uuid,_department text) RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path=public AS $$ BEGIN IF NOT public.has_role(auth.uid(),'admin') THEN RAISE EXCEPTION 'Forbidden'; END IF; PERFORM id FROM public.erp_records WHERE id=_book_id AND kind='book' FOR UPDATE; IF NOT FOUND THEN RAISE EXCEPTION 'Book not found'; END IF; UPDATE public.book_movements SET left_at=now() WHERE book_id=_book_id AND left_at IS NULL; INSERT INTO public.book_movements(book_id,department,actor_id) VALUES(_book_id,_department,auth.uid()); UPDATE public.erp_records SET payload=jsonb_set(payload,'{department}',to_jsonb(_department)) WHERE id=_book_id; END $$;
REVOKE ALL ON FUNCTION public.route_book(uuid,text) FROM PUBLIC; GRANT EXECUTE ON FUNCTION public.route_book(uuid,text) TO authenticated;
CREATE TABLE public.book_signatures(id uuid PRIMARY KEY DEFAULT gen_random_uuid(),book_id uuid REFERENCES public.erp_records(id) ON DELETE CASCADE NOT NULL,user_id uuid NOT NULL,signer_name text NOT NULL,image text NOT NULL,created_at timestamptz NOT NULL DEFAULT now());
GRANT SELECT,INSERT ON public.book_signatures TO authenticated; GRANT ALL ON public.book_signatures TO service_role;
ALTER TABLE public.book_signatures ENABLE ROW LEVEL SECURITY;
CREATE POLICY signature_read ON public.book_signatures FOR SELECT TO authenticated USING(EXISTS(SELECT 1 FROM public.user_roles WHERE user_id=auth.uid()));
CREATE POLICY signature_own ON public.book_signatures FOR INSERT TO authenticated WITH CHECK(user_id=auth.uid() AND EXISTS(SELECT 1 FROM public.user_roles WHERE user_id=auth.uid()));
CREATE TABLE public.gps_locations(user_id uuid PRIMARY KEY,vehicle_id uuid REFERENCES public.erp_records(id),latitude double precision NOT NULL,longitude double precision NOT NULL,accuracy double precision,updated_at timestamptz NOT NULL DEFAULT now());
GRANT SELECT,INSERT,UPDATE,DELETE ON public.gps_locations TO authenticated; GRANT ALL ON public.gps_locations TO service_role;
ALTER TABLE public.gps_locations ENABLE ROW LEVEL SECURITY;
CREATE POLICY gps_read ON public.gps_locations FOR SELECT TO authenticated USING(user_id=auth.uid() OR public.has_role(auth.uid(),'admin'));
CREATE POLICY gps_own ON public.gps_locations FOR ALL TO authenticated USING(user_id=auth.uid()) WITH CHECK(user_id=auth.uid());
INSERT INTO public.erp_records(id,kind,name,payload) VALUES
('11111111-1111-4111-8111-111111111111','sector','قطاع الزهور','{"manager":"أحمد محمود","employees":42,"progress":78}'),
('22222222-2222-4222-8222-222222222222','sector','المنطقة القديمة','{"manager":"عمر خالد","employees":36,"progress":65}'),
('33333333-3333-4333-8333-333333333333','sector','باب نركال','{"manager":"محمد سالم","employees":28,"progress":91}'),
('44444444-4444-4444-8444-444444444444','book','تأهيل الطرق الرئيسية في قطاع الزهور','{"number":"2026/1042","source":"وزارة الإعمار والإسكان والبلديات","department":"قطاع الزهور","status":"قيد الإجراء","priority":"عاجل","date":"2026-11-26"}'),
('55555555-5555-4555-8555-555555555555','book','خطة رفع الأنقاض في المنطقة القديمة','{"number":"2026/1041","source":"وزارة الإعمار والإسكان والبلديات","department":"المدير","status":"بانتظار التوقيع","priority":"عادي","date":"2026-11-26"}'),
('66666666-6666-4666-8666-666666666666','book','تخصيص آليات لحملة النظافة','{"number":"2026/1040","source":"محافظة نينوى","department":"قسم الآليات","status":"مكتمل","priority":"عادي","date":"2026-11-25"}'),
('77777777-7777-4777-8777-777777777777','vehicle','كابسة نفايات 01','{"plate":"نينوى 23451","driver":"علي حسن","status":"في الميدان","sector":"قطاع الزهور"}'),
('88888888-8888-4888-8888-888888888888','vehicle','شاحنة رفع أنقاض 02','{"plate":"نينوى 17620","driver":"خالد محمود","status":"متوقفة","sector":"المنطقة القديمة"}');
INSERT INTO public.erp_records(kind,name,sector_id,payload) VALUES
('department','قسم الخدمات','11111111-1111-4111-8111-111111111111','{"type":"قسم","manager":"أحمد محمود"}'),
('department','شعبة النظافة','11111111-1111-4111-8111-111111111111','{"type":"شعبة","manager":"علي حسن"}'),
('employee','أحمد محمود','11111111-1111-4111-8111-111111111111','{"role":"مسؤول القطاع","arrival":"07:55","departure":"—","achievements":"متابعة 8 كتب رسمية","status":"حاضر"}'),
('employee','علي حسن','11111111-1111-4111-8111-111111111111','{"role":"سائق آلية","arrival":"07:48","departure":"—","achievements":"إنجاز 3 جولات نظافة","status":"حاضر"}'),
('employee','عمر خالد','22222222-2222-4222-8222-222222222222','{"role":"مهندس مدني","arrival":"08:03","departure":"—","achievements":"الكشف على موقعين","status":"حاضر"}'),
('employee','محمد سالم','33333333-3333-4333-8333-333333333333','{"role":"مسؤول القطاع","arrival":"07:50","departure":"14:00","achievements":"إغلاق 5 معاملات","status":"منصرف"}');
INSERT INTO public.book_movements(book_id,department,entered_at,left_at) VALUES
('44444444-4444-4444-8444-444444444444','الإدارية • الوارد',now()-interval '5 hours',now()-interval '4 hours'),
('44444444-4444-4444-8444-444444444444','المدير',now()-interval '4 hours',now()-interval '2 hours'),
('44444444-4444-4444-8444-444444444444','قطاع الزهور',now()-interval '2 hours',NULL);