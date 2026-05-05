BEGIN;

WITH new_movies AS (
    SELECT
        'World War Z' AS title,
        'Former United Nations investigator Gerry Lane traverses the world in a race against time to stop a zombie pandemic.' AS description,
        2013 AS release_year,
        (SELECT language_id FROM public."language" WHERE lower(name) = 'english') AS language_id,
        7 AS rental_duration,
        4.99 AS rental_rate,
        116 AS length,
        'PG-13'::mpaa_rating AS rating
    UNION ALL
    SELECT
        'Pirates of the Caribbean: The Curse of the Black Pearl',
        'Blacksmith Will Turner teams up with eccentric pirate "Captain" Jack Sparrow to save his love from Jack''s former allies.',
        2003,
        (SELECT language_id FROM public."language" WHERE lower(name) = 'english'),
        14,
        9.99,
        143,
        'PG-13'::mpaa_rating
    UNION ALL
    SELECT
        'The Lord of the Rings: The Fellowship of the Ring',
        'A meek Hobbit from the Shire and eight companions set out on a journey to destroy the powerful One Ring.',
        2001,
        (SELECT language_id FROM public."language" WHERE lower(name) = 'english'),
        21,
        19.99,
        178,
        'PG-13'::mpaa_rating
),
inserted_movies AS (
    INSERT INTO public.film (
        title, description, release_year, language_id,
        rental_duration, rental_rate, "length", rating, last_update
    )
    SELECT
        nm.title, nm.description, nm.release_year, nm.language_id,
        nm.rental_duration, nm.rental_rate, nm.length, nm.rating, CURRENT_DATE
    FROM new_movies nm
    WHERE NOT EXISTS (
        SELECT 1
        FROM public.film f
        WHERE f.title = nm.title
          AND f.release_year = nm.release_year
    )
    RETURNING film_id, title, release_year, rental_duration, rental_rate, last_update
)
SELECT * FROM inserted_movies;

WITH new_actors AS (
    SELECT 'Brad' AS first_name, 'Pitt' AS last_name, 'World War Z' AS title
    UNION ALL SELECT 'Mireille', 'Enos', 'World War Z'
    UNION ALL SELECT 'Johnny', 'Depp', 'Pirates of the Caribbean: The Curse of the Black Pearl'
    UNION ALL SELECT 'Orlando', 'Bloom', 'Pirates of the Caribbean: The Curse of the Black Pearl'
    UNION ALL SELECT 'Elijah', 'Wood', 'The Lord of the Rings: The Fellowship of the Ring'
    UNION ALL SELECT 'Ian', 'McKellen', 'The Lord of the Rings: The Fellowship of the Ring'
),
insert_actors AS (
    INSERT INTO public.actor (first_name, last_name, last_update)
    SELECT DISTINCT
        na.first_name,
        na.last_name,
        CURRENT_DATE
    FROM new_actors na
    WHERE NOT EXISTS (
        SELECT 1
        FROM public.actor a
        WHERE a.first_name = na.first_name
          AND a.last_name = na.last_name
    )
    RETURNING actor_id, first_name, last_name
)
INSERT INTO public.film_actor (actor_id, film_id, last_update)
SELECT
    a.actor_id,
    f.film_id,
    CURRENT_DATE
FROM new_actors na
JOIN public.actor a
    ON a.first_name = na.first_name
   AND a.last_name = na.last_name
JOIN public.film f
    ON f.title = na.title
ON CONFLICT DO NOTHING;

WITH selected_store AS (
    SELECT store_id
    FROM public.store
    ORDER BY store_id
    LIMIT 1
),
films_to_inventory AS (
    SELECT film_id, title
    FROM public.film
    WHERE title IN (
        'World War Z',
        'Pirates of the Caribbean: The Curse of the Black Pearl',
        'The Lord of the Rings: The Fellowship of the Ring'
    )
)
INSERT INTO public.inventory (film_id, store_id, last_update)
SELECT
    fti.film_id,
    ss.store_id,
    CURRENT_DATE
FROM films_to_inventory fti
CROSS JOIN selected_store ss
WHERE NOT EXISTS (
    SELECT 1
    FROM public.inventory i
    WHERE i.film_id = fti.film_id
      AND i.store_id = ss.store_id
);

WITH existing_me AS (
    SELECT customer_id
    FROM public.customer
    WHERE first_name = 'Rahim'
      AND last_name = 'Kilibay'
      AND email = 'rkilibay23@apec.edu.kz'
    LIMIT 1
),
eligible_customer AS (
    SELECT c.customer_id
    FROM public.customer c
    JOIN public.rental r ON c.customer_id = r.customer_id
    JOIN public.payment p ON c.customer_id = p.customer_id
    WHERE NOT EXISTS (SELECT 1 FROM existing_me)
    GROUP BY c.customer_id
    HAVING COUNT(DISTINCT r.rental_id) >= 43
       AND COUNT(DISTINCT p.payment_id) >= 43
    ORDER BY COUNT(DISTINCT r.rental_id) DESC
    LIMIT 1
),
target_customer AS (
    SELECT customer_id FROM existing_me
    UNION ALL
    SELECT customer_id FROM eligible_customer
    LIMIT 1
),
selected_address AS (
    SELECT address_id
    FROM public.address
    ORDER BY address_id
    LIMIT 1
)
UPDATE public.customer c
SET
    first_name = 'Rahim',
    last_name = 'Kilibay',
    email = 'rkilibay23@apec.edu.kz',
    address_id = (SELECT address_id FROM selected_address),
    last_update = CURRENT_DATE
WHERE c.customer_id = (SELECT customer_id FROM target_customer);

SELECT *
FROM public.payment
WHERE customer_id = (
    SELECT customer_id
    FROM public.customer
    WHERE first_name = 'Rahim'
      AND last_name = 'Kilibay'
      AND email = 'rkilibay23@apec.edu.kz'
    LIMIT 1
);

DELETE FROM public.payment
WHERE customer_id = (
    SELECT customer_id
    FROM public.customer
    WHERE first_name = 'Rahim'
      AND last_name = 'Kilibay'
      AND email = 'rkilibay23@apec.edu.kz'
    LIMIT 1
);

SELECT *
FROM public.rental
WHERE customer_id = (
    SELECT customer_id
    FROM public.customer
    WHERE first_name = 'Rahim'
      AND last_name = 'Kilibay'
      AND email = 'rkilibay23@apec.edu.kz'
    LIMIT 1
);

DELETE FROM public.rental
WHERE customer_id = (
    SELECT customer_id
    FROM public.customer
    WHERE first_name = 'Rahim'
      AND last_name = 'Kilibay'
      AND email = 'rkilibay23@apec.edu.kz'
    LIMIT 1
);

WITH selected_customer AS (
    SELECT customer_id
    FROM public.customer
    WHERE first_name = 'Rahim'
      AND last_name = 'Kilibay'
      AND email = 'rkilibay23@apec.edu.kz'
    LIMIT 1
),
selected_staff AS (
    SELECT staff_id
    FROM public.staff
    ORDER BY staff_id
    LIMIT 1
),
selected_store AS (
    SELECT store_id
    FROM public.store
    ORDER BY store_id
    LIMIT 1
),
film_inventory AS (
    SELECT DISTINCT ON (f.title)
        f.title,
        f.rental_duration,
        i.inventory_id
    FROM public.film f
    JOIN public.inventory i ON f.film_id = i.film_id
    JOIN selected_store ss ON i.store_id = ss.store_id
    WHERE f.title IN (
        'World War Z',
        'Pirates of the Caribbean: The Curse of the Black Pearl',
        'The Lord of the Rings: The Fellowship of the Ring'
    )
    ORDER BY f.title, i.inventory_id
),
new_rentals AS (
    SELECT
        DATE '2017-01-15' AS rental_date,
        fi.inventory_id,
        sc.customer_id,
        DATE '2017-01-15' + fi.rental_duration * INTERVAL '1 day' AS return_date,
        ss.staff_id
    FROM film_inventory fi
    CROSS JOIN selected_customer sc
    CROSS JOIN selected_staff ss
),
inserted_rentals AS (
    INSERT INTO public.rental (
        rental_date,
        inventory_id,
        customer_id,
        return_date,
        staff_id,
        last_update
    )
    SELECT
        nr.rental_date,
        nr.inventory_id,
        nr.customer_id,
        nr.return_date,
        nr.staff_id,
        CURRENT_DATE
    FROM new_rentals nr
    WHERE NOT EXISTS (
        SELECT 1
        FROM public.rental r
        WHERE r.inventory_id = nr.inventory_id
          AND r.customer_id = nr.customer_id
          AND r.rental_date = nr.rental_date
    )
    RETURNING rental_id, inventory_id, customer_id
)
SELECT * FROM inserted_rentals;

WITH selected_customer AS (
    SELECT customer_id
    FROM public.customer
    WHERE first_name = 'Rahim'
      AND last_name = 'Kilibay'
      AND email = 'rkilibay23@apec.edu.kz'
    LIMIT 1
),
selected_staff AS (
    SELECT staff_id
    FROM public.staff
    ORDER BY staff_id
    LIMIT 1
),
rented_films AS (
    SELECT
        r.rental_id,
        r.customer_id,
        f.rental_rate
    FROM public.rental r
    JOIN public.inventory i ON r.inventory_id = i.inventory_id
    JOIN public.film f ON i.film_id = f.film_id
    WHERE r.customer_id = (SELECT customer_id FROM selected_customer)
      AND f.title IN (
          'World War Z',
          'Pirates of the Caribbean: The Curse of the Black Pearl',
          'The Lord of the Rings: The Fellowship of the Ring'
      )
)
INSERT INTO public.payment (
    customer_id,
    staff_id,
    rental_id,
    amount,
    payment_date
)
SELECT
    rf.customer_id,
    ss.staff_id,
    rf.rental_id,
    rf.rental_rate,
    TIMESTAMP '2017-01-15 10:00:00'
FROM rented_films rf
CROSS JOIN selected_staff ss
WHERE NOT EXISTS (
    SELECT 1
    FROM public.payment p
    WHERE p.customer_id = rf.customer_id
      AND p.rental_id = rf.rental_id
      AND p.amount = rf.rental_rate
      AND p.payment_date::DATE = DATE '2017-01-15'
);

COMMIT;