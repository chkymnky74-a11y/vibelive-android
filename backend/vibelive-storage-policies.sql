-- VibeLive — storage policies for buckets avatars / covers / post-media
-- Public read (buckets are public); writes only inside your own folder:
-- upload path must start with your user id, e.g. avatars/<uid>/pic.jpg

drop policy if exists "vibelive storage public read" on storage.objects;
create policy "vibelive storage public read" on storage.objects
  for select using (bucket_id in ('avatars','covers','post-media'));

drop policy if exists "vibelive storage insert own" on storage.objects;
create policy "vibelive storage insert own" on storage.objects
  for insert with check (
    bucket_id in ('avatars','covers','post-media')
    and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "vibelive storage update own" on storage.objects;
create policy "vibelive storage update own" on storage.objects
  for update using (
    bucket_id in ('avatars','covers','post-media')
    and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "vibelive storage delete own" on storage.objects;
create policy "vibelive storage delete own" on storage.objects
  for delete using (
    bucket_id in ('avatars','covers','post-media')
    and (storage.foldername(name))[1] = auth.uid()::text);
