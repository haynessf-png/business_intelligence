con = DBI::dbConnect(RSQLite::SQLite(), "data/midwest_airbnb.db")

client = ellmer::chat_openai(
  model  = "gpt-5.6-luna",
  params = ellmer::params(reasoning_effort = "none")
)

tryCatch({
  client$chat("Reply with only OK.")
  message("AI connection test succeeded")
}, error = function(e) {
  message("AI connection test failed: ", conditionMessage(e))
})

qc = querychat::querychat(
  con, "listings",
  client = client,
  tools = c("filter", "query", "visualize"),
  greeting = "Ask me about 14,887 Airbnb listings in Chicago, Columbus, and the Twin Cities.",
  data_description = "data/data_desc.md",
  extra_instructions = "data/extra_instructions.md"
)

library(shiny)
library(bslib)

ui = page_sidebar(
  title = "Midwest Airbnb Explorer",
  theme = bs_theme(
    primary = "#23395B",
    base_font = "Arial"
  ),
  sidebar = qc$sidebar(width = 350),
  
  card(
    card_header("Airbnb Listings"),
    DT::DTOutput("table")
  ),
  
  card(
    card_header("SQL Query"),
    verbatimTextOutput("sql")
  ),
  
  card(
    card_header("About"),
    p("Built by Scarlett Haynes."),
    p("Explore 14,887 Airbnb listings in Chicago, Columbus,
      and the Twin Cities. Ask questions to compare cities
      and find listings.")
  )
)

server = function(input, output, session) {
  vals = qc$server()
  
  output$table = DT::renderDT(
    vals$df(),
    options = list(pageLength = 10)
  )
  
  output$sql = renderText({
    sql = vals$sql()
    if (is.null(sql)) "SELECT * FROM listings" else sql
  })
}

shiny::shinyApp(ui, server)

