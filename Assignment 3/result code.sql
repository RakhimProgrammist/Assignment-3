SELECT *
FROM public.film
WHERE title IN (
    'World War Z',
    'Pirates of the Caribbean: The Curse of the Black Pearl',
    'The Lord of the Rings: The Fellowship of the Ring'
);


SELECT
    f.title,
    a.first_name,
    a.last_name
FROM public.film f
JOIN public.film_actor fa ON f.film_id = fa.film_id
JOIN public.actor a ON fa.actor_id = a.actor_id
WHERE f.title IN (
    'World War Z',
    'Pirates of the Caribbean: The Curse of the Black Pearl',
    'The Lord of the Rings: The Fellowship of the Ring'
)
ORDER BY f.title;


SELECT
    f.title,
    i.inventory_id,
    i.store_id
FROM public.inventory i
JOIN public.film f ON i.film_id = f.film_id
WHERE f.title IN (
    'World War Z',
    'Pirates of the Caribbean: The Curse of the Black Pearl',
    'The Lord of the Rings: The Fellowship of the Ring'
);


SELECT *
FROM public.customer
WHERE first_name = 'Rahim'
  AND last_name = 'Kilibay'
  AND email = 'rkilibay23@apec.edu.kz';


SELECT
    r.rental_id,
    f.title,
    r.rental_date,
    r.return_date
FROM public.rental r
JOIN public.inventory i ON r.inventory_id = i.inventory_id
JOIN public.film f ON i.film_id = f.film_id
WHERE r.customer_id = (
    SELECT customer_id
    FROM public.customer
    WHERE first_name = 'Rahim'
      AND last_name = 'Kilibay'
      AND email = 'rkilibay23@apec.edu.kz'
);


SELECT
    p.payment_id,
    f.title,
    p.amount,
    p.payment_date
FROM public.payment p
JOIN public.rental r ON p.rental_id = r.rental_id
JOIN public.inventory i ON r.inventory_id = i.inventory_id
JOIN public.film f ON i.film_id = f.film_id
WHERE p.customer_id = (
    SELECT customer_id
    FROM public.customer
    WHERE first_name = 'Rahim'
      AND last_name = 'Kilibay'
      AND email = 'rkilibay23@apec.edu.kz'
);