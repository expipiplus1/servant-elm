{-# LANGUAGE DataKinds         #-}
{-# LANGUAGE DeriveGeneric     #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TypeOperators     #-}

module GenerateSpec where

import           Test.Hspec

import           Control.Monad (zipWithM_)
import           Data.Aeson    (ToJSON)
import           Data.Monoid   ((<>))
import qualified Data.Text.IO  as T
import           GHC.Generics  (Generic)
import           Servant.API
import           Servant.Elm


data Book = Book
  { title :: String
  } deriving Generic

instance ToJSON Book
instance ElmType Book


type TestApi =
       "one"     :> Get '[JSON] Int
  :<|> "two"     :> ReqBody '[JSON] String
                 :> Post '[JSON] (Maybe Int)
  :<|> "books"   :> Capture "id" Int
                 :> Get '[JSON] Book
  :<|> "books"   :> Capture "title" String
                 :> Get '[JSON] Book
  :<|> "books"   :> QueryFlag "published"
                 :> QueryParam "sort" String
                 :> QueryParam "year" Int
                 :> QueryParams "filters" (Maybe Bool)
                 :> Get '[JSON] [Book]
  :<|> "books"   :> ReqBody '[JSON] Book
                 :> PostNoContent '[JSON] NoContent
  :<|> "nothing" :> GetNoContent '[JSON] NoContent
  :<|> "with-a-header" :> Header "myStringHeader" String
                       :> Header "myIntHeader" Int
                       :> Get '[JSON] String

testApi :: Proxy TestApi
testApi = Proxy

spec :: Test.Hspec.Spec
spec = do
  describe "encoding a simple api" $ do
    it "does it" $ do
      expected <- mapM T.readFile
        [ "test/getOneSource.elm"
        , "test/postTwoSource.elm"
        , "test/getBooksByIdSource.elm"
        , "test/getBooksByTitleSource.elm"
        , "test/getBooksSource.elm"
        , "test/emptyResponseHandlerSource.elm"
        , "test/handleResponseSource.elm"
        , "test/promoteErrorSource.elm"
        , "test/postBooksSource.elm"
        , "test/getNothingSource.elm"
        , "test/getWithaheaderSource.elm"
        ]

      let generated = map (<> "\n") (generateElmForAPI testApi)

      generated `itemsShouldBe` expected

itemsShouldBe :: (Monoid a, Eq a, Show a) => [a] -> [a] -> IO ()
itemsShouldBe actual expected =
  zipWithM_ shouldBe (actual   ++ replicate (length expected - length actual) mempty)
                     (expected ++ replicate (length actual - length expected) mempty)
