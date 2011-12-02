module SlackStack.Handlers.RSS (
    rssHandler
) where

import SlackStack.Util
import Data.Maybe (fromJust,isNothing)
import qualified SlackStack.Util.DB as DB

import Happstack.Server hiding (asContentType)
import Data.ByteString.UTF8
import Control.Monad.Trans (liftIO)

import Data.Maybe (fromJust)
import qualified Text.RSS as RSS
import Network.URI (URI,parseURI)
import qualified Data.Map as M

import Text.Regex (mkRegex,subRegex)

import System.Time.ParseDate (parseCalendarTime)
import System.Locale (defaultTimeLocale)

rssHandler :: DB.IConnection conn => conn -> ServerPartT IO Response
rssHandler dbh = dir "rss" $ methodSP GET $ do
    posts <- liftIO $ DB.rowMaps dbh
        "select id,title,description,timestamp from posts \
        \order by timestamp desc" []
    
    return $ asContentType "application/rss+xml" $ toResponse
        $ RSS.showXML $ RSS.rssToXML $ rssFromPosts posts
    
rssFromPosts :: [M.Map String DB.SqlValue] -> RSS.RSS
rssFromPosts posts = RSS.RSS
    "The Universe of Discord"
    (uri "http://substack.net")
    "Pictures of robots with words in between"
    [
        RSS.WebMaster "mail@substack.net",
        RSS.Image
            (uri "http://substack.net/images/substackistan.png")
            "The Universe of Discord"
            (uri "http://substack.net")
            (Just 107) (Just 71) Nothing
    ]
    (map rssify posts)
    
rssify :: M.Map String DB.SqlValue -> RSS.Item
rssify post =
    (RSS.Title title)
    : (RSS.Description desc)
    : (RSS.Source (uri link) title)
    : (RSS.Link $ uri link)
    : mDate
    where
        link = "http://substack.net/posts/" ++ pid ++ "/" ++ stripper title
        
        f DB.SqlNull = ""
        f x = DB.fromSql x
        
        [pid,title,desc,timestamp] = map (f . (post M.!))
            $ words "id title description timestamp"
        
        format = "%Y-%m-%d %H:%M:%S"
        locale = defaultTimeLocale
        mDate = case parseCalendarTime locale format timestamp of
            Just d -> [ RSS.PubDate d ]
            Nothing -> []

uri :: String -> URI
uri = fromJust . parseURI

subRegex' re rep str = subRegex re str rep
stripper = subRegex' (mkRegex "^-|-$") "" . subRegex' (mkRegex "[^A-Za-z0-9]+") "-"
