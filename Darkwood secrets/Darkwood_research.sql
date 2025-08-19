/* Проект «Секреты Тёмнолесья»
 * Цель проекта: изучить влияние характеристик игроков и их игровых персонажей 
 * на покупку внутриигровой валюты «райские лепестки», а также оценить 
 * активность игроков при совершении внутриигровых покупок
 * 
 * Автор: Крылов Дмитрий Сергеевич
 * Дата: 10.04.2025
*/

-- Часть 1. Исследовательский анализ данных
-- Задача 1. Исследование доли платящих игроков

-- 1.1. Доля платящих пользователей по всем данным:
-- Напишите ваш запрос здесь
SELECT
    COUNT(DISTINCT id) AS total_players,  -- Общее количество игроков (a)
    SUM(payer) AS paying_players,         -- Количество платящих игроков (b)
    ROUND(SUM(payer)::numeric / COUNT(DISTINCT id)::numeric, 2) AS paying_ratio  -- Доля платящих игроков в % (c)
FROM fantasy.users;

-- 1.2. Доля платящих пользователей в разрезе расы персонажа:
WITH df AS (
	SELECT
		DISTINCT(race) AS race,
		COUNT(*) OVER(PARTITION BY race) AS players_over_race,
		SUM(payer) OVER(PARTITION BY race) AS payers_over_race
	FROM fantasy.users u
	INNER JOIN fantasy.race r ON u.race_id = r.race_id
)
SELECT *,
	ROUND(payers_over_race::numeric / players_over_race::numeric, 2) AS paying_ratio
FROM df;
-- Напишите ваш запрос здесь

-- Задача 2. Исследование внутриигровых покупок

-- 2.1. Статистические показатели по полю amount:
-- Напишите ваш запрос здесь
SELECT 
	COUNT(*) AS total_transactions,
	SUM(amount) AS total_sum_of_transactions,
	MIN(amount) AS min_transaction,
	MAX(amount) AS max_transaction,	
	AVG(amount) AS avg_transaction,
	PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY amount) AS median_transaction,
	STDDEV(amount) AS stdev_transaction
FROM fantasy.events e;

-- 2.2: Аномальные нулевые покупки:
-- Напишите ваш запрос здесь
SELECT 
	(SELECT COUNT(*) FROM fantasy.events e WHERE amount = 0) AS null_transactions,
	COUNT(*) AS all_transactions,
	(SELECT COUNT(*)::numeric FROM fantasy.events e WHERE amount = 0)/COUNT(*)::numeric 
	AS percent_of_transactions
FROM fantasy.events e;

-- 2.3: Сравнительный анализ активности платящих и неплатящих игроков:
-- Напишите ваш запрос здесь
SELECT 
	COUNT(DISTINCT CASE WHEN payer = 1 THEN e.id END) AS payer_users,
	COUNT(CASE WHEN payer = 1 THEN transaction_id END) / COUNT(DISTINCT CASE WHEN payer = 1 THEN e.id END) 
	AS avg_tools_per_payer_users,
	ROUND(AVG(CASE WHEN payer = 1 THEN amount END)::numeric, 2) AS avg_payer_users,
	COUNT(DISTINCT CASE WHEN payer = 0 THEN e.id END) AS none_payer_users,
	COUNT(CASE WHEN payer = 0 THEN transaction_id END) / COUNT(DISTINCT CASE WHEN payer = 0 THEN e.id END) 
	AS avg_tools_per_none_payer_users,
	ROUND(AVG(CASE WHEN payer = 0 THEN amount END)::numeric, 2) AS avg_none_payer_users
FROM fantasy.events e 
LEFT JOIN fantasy.users u ON
	e.id = u.id
WHERE e.amount > 0; -- Внеёс исправление, чтобы мы не допускали случаи, когда у нас "нулевые" покупки 

-- 2.4: Популярные эпические предметы:
-- Напишите ваш запрос здесь
-- Количество пользователей, которые хотя бы раз 
WITH total_count AS (
    SELECT 
        i.game_items,
        COUNT(*) AS total_sales,
        COUNT(DISTINCT e.id) AS unique_players  -- Доля игроков
    FROM fantasy.events e
    LEFT JOIN fantasy.items i ON e.item_code = i.item_code
    WHERE e.amount > 0  -- Фильтрация нулевых покупок
    GROUP BY i.game_items
)
SELECT 
    game_items,
    total_sales,
    ROUND(unique_players::NUMERIC / (SELECT COUNT(DISTINCT id) FROM fantasy.events WHERE amount > 0) * 100, 2) AS player_share,
    ROUND(total_sales::NUMERIC / SUM(total_sales) OVER() * 100, 2) AS sales_share
FROM total_count
ORDER BY total_sales DESC;  -- Произвёл сортировку по убыванию

-- Часть 2. Решение ad hoc-задач
-- Задача 1. Зависимость активности игроков от расы персонажа:
-- Напишите ваш запрос здесь
WITH 
-- Общее количество игроков по расе
total_players AS (
    SELECT 
        r.race,
        COUNT(DISTINCT u.id) AS total_players
    FROM fantasy.users u
    INNER JOIN fantasy.race r ON u.race_id = r.race_id
    GROUP BY r.race
),
-- Покупатели и платящие покупатели
buyers AS (
    SELECT 
        r.race,
        COUNT(DISTINCT e.id) AS players_with_purchases,
        COUNT(DISTINCT CASE WHEN u.payer = 1 THEN e.id END) AS paying_players
    FROM fantasy.events e
    INNER JOIN fantasy.users u ON e.id = u.id
    INNER JOIN fantasy.race r ON u.race_id = r.race_id
    WHERE e.amount > 0  -- Фильтрация нулевых покупок
    GROUP BY r.race
),
-- Статистика по покупкам
purchase_stats AS (
    SELECT 
        r.race,
        COUNT(e.transaction_id) AS total_transactions,
        SUM(e.amount) AS total_amount
    FROM fantasy.events e
    INNER JOIN fantasy.users u ON e.id = u.id
    INNER JOIN fantasy.race r ON u.race_id = r.race_id
    WHERE e.amount > 0
    GROUP BY r.race
)
-- Финальный запрос
SELECT 
    tp.race,
    tp.total_players,
    b.players_with_purchases,
    ROUND(b.players_with_purchases::NUMERIC / tp.total_players, 2) AS purchase_ratio,
    ROUND(b.paying_players::NUMERIC / b.players_with_purchases, 2) AS payer_ratio,
    ROUND(ps.total_transactions::NUMERIC / b.players_with_purchases, 2) AS avg_transactions_per_player,
    ROUND(ps.total_amount::NUMERIC / ps.total_transactions, 2) AS avg_transaction_amount,
    ROUND(ps.total_amount::NUMERIC / b.players_with_purchases, 2) AS avg_total_amount_per_player
FROM total_players tp
LEFT JOIN buyers b ON tp.race = b.race
LEFT JOIN purchase_stats ps ON tp.race = ps.race
ORDER BY tp.race;

-- Задача 2: Частота покупок
-- Напишите ваш запрос здесь
WITH
filtered_events AS (
    SELECT 
        e.id AS event_id,
        e.transaction_id,
        TO_DATE(e.date, 'YYYY-MM-DD') AS date,
        u.id AS user_id,          
        u.payer
    FROM fantasy.events e
    INNER JOIN fantasy.users u 
        ON e.id = u.id  
    WHERE e.amount > 0
),
purchase_intervals AS (
    SELECT 
        user_id,
        date,
        (date - LAG(date) OVER (
            PARTITION BY user_id 
            ORDER BY date
        )) AS days_between,
        payer
    FROM filtered_events
),
player_stats AS (
    SELECT 
        user_id,
        MAX(payer) AS payer,
        COUNT(*) AS total_transactions,
        AVG(days_between) AS avg_days_between
    FROM purchase_intervals
    GROUP BY user_id
    HAVING COUNT(*) >= 25
),
ranked_players AS (
    SELECT 
        *,
        NTILE(3) OVER (ORDER BY avg_days_between) AS frequency_group
    FROM player_stats
),
frequency_groups AS (
    SELECT 
        user_id,
        CASE frequency_group
            WHEN 1 THEN 'высокая частота'
            WHEN 2 THEN 'умеренная частота'
            ELSE 'низкая частота'
        END AS frequency_category,
        total_transactions,
        payer,
        avg_days_between
    FROM ranked_players
)
SELECT 
    frequency_category,
    COUNT(user_id) AS players_count,
    SUM(payer) AS paying_players,
    ROUND(SUM(payer)::NUMERIC / COUNT(user_id), 2) AS paying_ratio,
    ROUND(AVG(total_transactions), 2) AS avg_transactions_per_player,
    ROUND(AVG(avg_days_between), 2) AS avg_days_between
FROM frequency_groups
GROUP BY frequency_category
ORDER BY 
    CASE frequency_category
        WHEN 'высокая частота' THEN 1
        WHEN 'умеренная частота' THEN 2
        ELSE 3
    END;