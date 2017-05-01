-- Create tables for classes, students and enrollment
CREATE TABLE users (
    id          SERIAL PRIMARY KEY,
    name        TEXT,
    login       TEXT
);
CREATE TABLE video (
    id          SERIAL PRIMARY KEY,
    name        TEXT
);
CREATE TABLE videoliked (
    vedio       INTEGER REFERENCES video (id) NOT NULL,
    start_time  TIME,
    end_time    TIME
);
CREATE TABLE videowatched (
    video       INTEGER REFERENCES video (id) NOT NULL,
    start_time  TIME,
    end_time    TIME
);
CREATE TABLE timesloggedin (
    users        INTEGER REFERENCES users (id) NOT NULL,
    video       INTEGER REFERENCES video (id) NOT NULL,
    times       INTEGER
);
CREATE TABLE friend (
    subject INTEGER REFERENCES users (id) NOT NULL,
    object INTEGER REFERENCES users (id) NOT NULL
);

-- Overall likes
SELECT video.video_id, video.video_name, COUNT(*) like_count
FROM cats.likes like1, cats.video video
WHERE like1.video_id = video.video_id
GROUP BY video.video_id
ORDER BY like_count DESC
LIMIT 10

-- Friend likes
SELECT video.video_id, video.video_name, COUNT(*) like_count
FROM cats.userS user1, cats.likes like1, cats.video video, cats.friend friend
WHERE like1.user_id = friend.friend_id
	 AND friend.user_id = user1.user_id
	 AND user1.user_name = 'X'
	 AND like1.video_id = video.video_id
GROUP BY video.video_id
ORDER BY like_count DESC
LIMIT 10


-- Friends-of Friends likes
SELECT video.video_id, video.video_name, COUNT(*) like_count
FROM cats.video video, cats.likes like1
WHERE video.video_id = like1.video_id 
  AND like1.user_id IN ((select friend.friend_id
                    FROM cats.users users, cats.friend friend
                    WHERE users.user_id = friend.user_id
                      AND users.user_name = 'X'
                   ) UNION
                   (SELECT ff.friend_id
                    FROM cats.users users, cats.friend friend, cats.friend ff
                    WHERE users.user_id = friend.user_id AND friend.friend_id = ff.user_id 
                      AND users.user_name = 'X'
                   ))
GROUP BY video.video_id
ORDER BY like_count DESC LIMIT 10


-- My kind of cats
SELECT video.video_id, video.video_name, COUNT(*) like_count
FROM cats.users user1, cats.likes like1, cats.video video
WHERE user1.user_name = 'X'
	  AND like1.user_id = user1.user_id
      AND EXISTS(SELECT * 
      			FROM cats.likes like1, cats.video video
      			WHERE like1.video_id = video.video_id
                )
GROUP BY video.video_id
ORDER BY like_count DESC
LIMIT 10


-- My kind of cats with perference
WITH user_weight AS
(SELECT like1.user_id, LOG(1+COUNT(*)) AS weight
 FROM cats.likes like1
 WHERE like1.video_id in (SELECT xl.video_id
                      FROM cats.users u, cats.likes xl
                      WHERE u.user_id = xl.user_id
                      AND u.user_name = 'X')
GROUP BY like1.user_id)
SELECT video.video_id, video.video_name, SUM(w.weight) score
FROM user_weight w, cats.likes like1, cats.video video
WHERE w.user_id = like1.user_id AND video.video_id = like1.video_id
GROUP BY video.video_id
ORDER BY score DESC
LIMIT 10

