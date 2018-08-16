var wager =
{
  "revision" : "255",
  "gameName" : "pwrb",
  "price" : 200,
  "boards" : [ {
    "selections" : [ "1", "2", "3", "4", "5", "11" ]
  } ]
}

var newBoard = wager.boards[0]
// for (var i=0; i<newBoard.selections; i++)
// {
//     newBoard.selections[i]++ // = newBoard.selections[i] * 2
// }
//console.log(newBoard.selections)
wager.boards.push(newBoard)
console.log(JSON.stringify(wager, ' ', 2))