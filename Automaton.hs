module Main where
    {--
        define custom types for States, Neighbourhoods, and the Rule bit string
    --}

    import Data.Char

    type State = Bool
    stateRepr :: State -> String
    stateRepr s = if s then "1" else " "

    bitToState :: Integer -> State
    bitToState b = b /= 0

    type Universe = [State]
    uToStr :: Universe -> String
    uToStr u = concat [stateRepr s | s <- u]

    type Rule = [State]

    type WolframCode = Integer

    data NeighbourHood = NeighbourHood {
        leftCell :: State,
        middleCell :: State,
        rightCell :: State
    } deriving Eq

    instance Show NeighbourHood
        where
            show ( NeighbourHood lc mc rc ) = show ( stateRepr lc ++ stateRepr mc ++ stateRepr rc )

    neighbourHoodToIx :: NeighbourHood -> Int
    neighbourHoodToIx n = sigma
        where
            sigma = (if leftCell n then 1 else 0)*4 +
                    (if middleCell n then 1 else 0)*2 +
                    (if rightCell n then 1 else 0)

    -- Extract neighbourhood given
    getNeighbours :: Universe -> Int -> NeighbourHood
    getNeighbours a n
            |n == 0 = NeighbourHood  (last $ a) (a !! n) (a !! (n + 1) )
            |n == (length a - 1) = NeighbourHood  (a !! (n - 1) ) (a !! n) (head $ a)
            |otherwise = NeighbourHood (a !! (n - 1) ) (a !! n) (a !! (n + 1) )

    printUniverse :: Universe -> IO()
    printUniverse u = putStrLn (uToStr u)

    {--
        An elementary cellular automaton can be stated as follows via the Wolfram Code

        1 byte representing the transitions from the following neighbourhoods:
        (it is 8 bits due to the fact that we are given 3 bits, 2^3 = 8)
        111	110	101	100	011	010	001	000
        b8  b7  b6  b5  b4  b3  b2  b1

        here is the algorithim we will use: WolframCode -> [State]
        then for all neighbourhoods in the Universe:
            map the neighbourhood to wolfram code index via getNeighbourHoodIx :: Neighbourhood -> Integer
            and using this value to index into the 
    --}

    -- Helper function to pad zeroes to ensure 8 bit size
    pad :: Rule -> Rule
    pad n
        | length n == 8 = reverse ( n )
        | otherwise = reverse (replicate (8 - length n) False ++ n)

    -- convert Wolfram Code to byte
    wolframCodeToByte :: WolframCode -> Rule
    wolframCodeToByte 0 = [False]
    wolframCodeToByte 1 = [True]
    wolframCodeToByte n = byte
        where
            byte = wolframCodeToByte (div n 2) ++ [bitToState (mod n 2)]


    -- Apply rule to cell given Rule byte and Neighbourhood
    applyRule :: Rule -> NeighbourHood -> State
    applyRule xs n = state
        where
            ix = neighbourHoodToIx n
            state = xs !! ix

    -- Seed Universe with only the center cell being True
    seedUniverse :: Integer -> Universe
    seedUniverse n = [ix == n `div` 2 | ix <- [0..n]]

    epoch :: [NeighbourHood] -> Rule -> Universe
    epoch n rule = [applyRule rule ix | ix <- n]

    -- Simulate N times, with rule byte B, Universe U outputs a new Universe
    nEpochs :: Int -> Rule -> Universe -> IO()
    nEpochs 0 rule u = putStr " "
    nEpochs epochs rule u = do 
        printUniverse newUniverse
        nEpochs (epochs-1) rule newUniverse
        where
            neighbourhoods = [getNeighbours u ix | ix <- [0..length u-1]]
            newUniverse = [applyRule rule n | n <- neighbourhoods]



    main :: IO()
    main = do
        putStrLn "Enter the Wolfram Code of the Rule. <eg : 30>"
        wcStr <- getLine
        let wc = read wcStr :: Integer

        putStrLn "Enter the length of the universe in cells"
        widthStr <- getLine
        let width = read widthStr :: Integer

        putStrLn "Enter the number of epochs to simulate"
        epochStr <- getLine
        let epochs = read epochStr :: Int

        let rule = pad (wolframCodeToByte wc )
        let universe = seedUniverse width

        printUniverse universe
        nEpochs epochs rule universe
