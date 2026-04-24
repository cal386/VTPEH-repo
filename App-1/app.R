# ── Shiny App ─────────────────────────────────────────────────────────────────
library(shiny)
library(leaflet)
library(tigris)
library(sf)
library(dplyr)
library(stringr)

# ── Load pre-cleaned data ─────────────────────────────────────────────────────
county_lead <- readRDS("county_lead.rds")

# ── Shapefile ─────────────────────────────────────────────────────────────────
ny_counties_geo <- counties(state = "NY", cb = TRUE, year = 2022) %>%
  st_transform(4326) %>%
  mutate(
    COUNTYFP_full = str_pad(GEOID, 5, pad = "0"),
    FIPS_5 = COUNTYFP_full
  )

# ── Color palette factory ─────────────────────────────────────────────────────
make_pal <- function(domain_vals) {
  colorNumeric(
    palette  = c("#ffffff", "#ffe5d9", "#fcbba1", "#fc9272",
                 "#fb6a4a", "#de2d26", "#a50f15"),
    domain   = domain_vals,
    na.color = "#d0d0d0"
  )
}

# ── Year range ────────────────────────────────────────────────────────────────
year_min <- min(county_lead$Year, na.rm = TRUE)
year_max <- max(county_lead$Year, na.rm = TRUE)

# ── UI ────────────────────────────────────────────────────────────────────────
ui <- fluidPage(
  tags$head(tags$style(HTML("
    @import url('https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap');

    * { box-sizing: border-box; }

    body {
      font-family: 'Inter', sans-serif;
      font-weight: 400;
      background-color: #f7f3ef;
      color: #2b1f1f;
      margin: 0;
      padding: 0;
    }

    .app-header {
      background-color: #2b1f1f;
      color: #f7f3ef;
      padding: 28px 40px 20px;
      border-bottom: 4px solid #a50f15;
    }
    .app-header h1 {
      font-family: 'Inter', sans-serif;
      font-weight: 700;
      font-size: 1.5em;
      margin: 0 0 5px 0;
      letter-spacing: -0.3px;
    }
    .app-header p {
      margin: 0;
      font-size: 0.85em;
      color: #c9b8b8;
      font-weight: 300;
    }

    .main-panel { padding: 24px 40px; }

    .slider-row {
      display: flex;
      align-items: center;
      gap: 16px;
      margin-bottom: 18px;
      background: #fff;
      border-radius: 8px;
      padding: 14px 20px;
      box-shadow: 0 2px 8px rgba(43,31,31,0.07);
      border: 1px solid #ddd0c8;
    }
    .slider-label {
      font-family: 'Inter', sans-serif;
      font-weight: 600;
      font-size: 0.9em;
      color: #2b1f1f;
      white-space: nowrap;
      text-transform: uppercase;
      letter-spacing: 0.5px;
    }

    .irs--shiny .irs-bar {
      background: #a50f15;
      border-top: 1px solid #a50f15;
      border-bottom: 1px solid #a50f15;
    }
    .irs--shiny .irs-handle {
      border: 2px solid #a50f15;
      background: #fff;
    }
    .irs--shiny .irs-from,
    .irs--shiny .irs-to,
    .irs--shiny .irs-single {
      background: #a50f15;
      font-family: 'Inter', sans-serif;
      font-size: 0.8em;
    }
    .irs--shiny .irs-min,
    .irs--shiny .irs-max {
      font-family: 'Inter', sans-serif;
      font-size: 0.75em;
      color: #888;
    }

    .slider-input-container { width: 100%; }

    .slider-animate-button {
      display: inline-flex !important;
      align-items: center;
      justify-content: center;
      width: 44px !important;
      height: 44px !important;
      border-radius: 50% !important;
      background-color: #a50f15 !important;
      border: none !important;
      box-shadow: 0 3px 12px rgba(165,15,21,0.40) !important;
      cursor: pointer !important;
      flex-shrink: 0;
      transition: background 0.2s, transform 0.15s !important;
      color: #fff !important;
      font-size: 18px !important;
      margin-left: 10px !important;
      text-decoration: none !important;
    }
    .slider-animate-button:hover {
      background-color: #7f0a10 !important;
      transform: scale(1.08) !important;
    }
    .slider-animate-button i {
      font-size: 16px !important;
    }

    #map {
      border-radius: 8px;
      box-shadow: 0 4px 24px rgba(43,31,31,0.13);
      border: 1px solid #ddd0c8;
    }

    #info_box {
      background: #ffffff;
      border-left: 5px solid #a50f15;
      border-radius: 6px;
      padding: 16px 22px;
      margin-top: 16px;
      font-size: 0.92em;
      box-shadow: 0 2px 10px rgba(43,31,31,0.07);
      min-height: 58px;
      font-family: 'Inter', sans-serif;
    }
    .info-label {
      color: #a50f15;
      font-weight: 600;
    }
    .big-rate {
      font-family: 'Inter', sans-serif;
      font-weight: 700;
      font-size: 1.5em;
      color: #a50f15;
    }

    .about-section {
      background: #ffffff;
      border-radius: 8px;
      border: 1px solid #ddd0c8;
      margin-top: 20px;
      box-shadow: 0 2px 8px rgba(43,31,31,0.06);
      overflow: hidden;
    }
    .about-toggle {
      width: 100%;
      background: none;
      border: none;
      padding: 16px 22px;
      text-align: left;
      cursor: pointer;
      display: flex;
      align-items: center;
      justify-content: space-between;
      font-family: 'Inter', sans-serif;
      font-weight: 600;
      font-size: 0.95em;
      color: #2b1f1f;
      transition: background 0.15s;
    }
    .about-toggle:hover { background: #fdf0ef; }
    .about-toggle .caret {
      font-size: 0.75em;
      color: #a50f15;
      transition: transform 0.25s;
    }
    .about-toggle.open .caret { transform: rotate(180deg); }
    .about-body {
      display: none;
      padding: 4px 22px 22px;
      font-size: 0.88em;
      line-height: 1.75;
      color: #3a2a2a;
      border-top: 1px solid #f0e8e5;
    }
    .about-body.open { display: block; }
    .about-body p { margin: 0.8em 0; }
    .about-body strong { color: #2b1f1f; }
    .about-body em { color: #555; }
    .about-body sup { font-size: 0.75em; vertical-align: super; color: #a50f15; }
    .about-body hr {
      border: none;
      border-top: 1px solid #eee;
      margin: 16px 0;
    }
    .about-body ol, .about-body ul {
      padding-left: 1.3em;
      margin: 0.5em 0;
      color: #555;
      font-size: 0.95em;
    }
    .about-body ol li, .about-body ul li { margin-bottom: 6px; }
    .about-body a { color: #a50f15; }

    .footer {
      text-align: center;
      color: #999;
      font-size: 0.75em;
      font-family: 'Inter', sans-serif;
      padding: 16px 0 28px;
      border-top: 1px solid #e0d6d0;
      margin-top: 20px;
    }
  "))),
  
  # ── Header ───────────────────────────────────────────────────────────────
  div(class = "app-header",
      h1("Childhood Blood Lead Levels — New York State (excluding NYC)"),
      p("Elevated blood lead incidence rate per 1,000 children tested, by county")
  ),
  
  div(class = "main-panel",
      
      # ── Year slider ─────────────────────────────────────────────────────────
      div(class = "slider-row",
          span(class = "slider-label", "Year"),
          div(class = "slider-input-container",
              sliderInput("year", label = NULL,
                          min = year_min, max = year_max,
                          value = year_min, step = 1,
                          sep = "", width = "100%",
                          animate = animationOptions(interval = 900, loop = FALSE))
          )
      ),
      
      # ── Map ─────────────────────────────────────────────────────────────────
      leafletOutput("map", height = "520px"),
      
      # ── Click info panel ────────────────────────────────────────────────────
      div(id = "info_box", uiOutput("county_info")),
      
      # ── About section ────────────────────────────────────────────────────────
      div(class = "about-section",
          tags$button(
            class = "about-toggle",
            id    = "about_btn",
            onclick = "
          var body = document.getElementById('about_body');
          var btn  = document.getElementById('about_btn');
          body.classList.toggle('open');
          btn.classList.toggle('open');
        ",
            span("Why did you make this app?"),
            span(class = "caret", "▼")
          ),
          div(id = "about_body", class = "about-body",
              HTML("
          <p>I wanted to see: is there a decrease in <strong>reported positive cases
          of elevated pediatric blood lead level</strong> <em>(varA)</em> over
          <strong>time in years</strong> <em>(varB)</em> in counties across NYS?</p>

          <p>I am interested in the link between geography and blood lead levels in
          children. Broadly, there is a public campaign to ensure that children are
          screened for blood lead levels routinely. Due to a variety of social,
          environmental, and economic factors, children of some backgrounds are more
          at risk of exposure to lead, which can have devastating long-term effects
          on development and overall health.<sup>1</sup> States typically have
          standards on providing blood lead testing for children. In the state of New
          York, all children are supposed to undergo regular checkups to screen for
          elevated blood lead testing.<sup>2</sup> These guidelines change frequently,
          as recently as 2019 for medical providers, and with rental registry laws in
          2025.<sup>2</sup> Around the country, there have been national efforts to
          improve drinking water via the 2021 Infrastructure Investment and Jobs Act;
          these projects are up to individual states to determine what gets priority
          first.<sup>3</sup> For New York State, municipalities with high populations
          of people of color and lower incomes are likely to be prioritized by the
          lead service line replacement program, as these individuals may be more at
          risk for elevated blood lead levels.<sup>3</sup></p>

          <hr>
          <strong>References</strong>
          <ol>
            <li>CDC. CDC Updates Blood Lead Reference Value. <em>Childhood Lead
            Poisoning Prevention.</em> Published April 2, 2024.
            <a href='https://www.cdc.gov/lead-prevention/php/news-features/updates-blood-lead-reference-value.html'
               target='_blank'>cdc.gov</a></li>
            <li>New York State Department of Health. Childhood Lead Poisoning
            Prevention. ny.gov. Accessed February 19, 2026.
            <a href='https://www.health.ny.gov/environmental/lead/'
               target='_blank'>health.ny.gov</a></li>
            <li>Lead Service Lines in NYC Disproportionately Impact Hispanic/Latino
            Communities and Children Already At Risk. Columbia University Mailman
            School of Public Health. Published August 30, 2023.
            <a href='https://www.publichealth.columbia.edu/news/lead-service-lines-nyc-disproportionately-impact-hispanic-latino-communities-children-already-risk-lead-exposure'
               target='_blank'>publichealth.columbia.edu</a></li>
          </ol>
        ")
          )
      ),
      
      # ── AI Disclosure ────────────────────────────────────────────────────────
      div(class = "about-section",
          tags$button(
            class = "about-toggle",
            id    = "ai_btn",
            onclick = "
          var body = document.getElementById('ai_body');
          var btn  = document.getElementById('ai_btn');
          body.classList.toggle('open');
          btn.classList.toggle('open');
        ",
            span("AI Use Disclosure"),
            span(class = "caret", "▼")
          ),
          div(id = "ai_body", class = "about-body",
              HTML("
          <p>This application was developed with the assistance of Claude (Anthropic),
          a large language model AI assistant. The following describes what was
          completed by the student and what was assisted by AI:</p>

          <p><strong>Completed independently by the student:</strong></p>
          <ul>
            <li>Identification of the research question and public health framing</li>
            <li>Selection and download of the primary dataset (NYS Childhood Blood
            Lead Testing) and FIPS crosswalk file</li>
            <li>Initial data exploration, type coercion, and column renaming</li>
            <li>County-level aggregation of zip-code data and calculation of
            Rate per 1,000</li>
            <li>Joining of FIPS codes to the aggregated county dataset</li>
            <li>Writing of the background text and references in the About section</li>
            <li>All decisions regarding research scope, variable selection,
            and interpretation</li>
          </ul>

          <p><strong>Assisted by AI (Claude, Anthropic):</strong></p>
          <ul>
            <li>Shiny app code structure, UI layout, and server logic</li>
            <li>Leaflet map integration, color palette design, and polygon rendering</li>
            <li>CSS styling for the app interface</li>
            <li>Debugging of deployment errors on ShinyApps.io, including FIPS
            join diagnostics and .rds file bundling</li>
            <li>Separation of the data preparation script from the app script</li>
          </ul>

          <p><em>All AI-generated code was reviewed, tested, and deployed by the
          student. The research question, data, and interpretive content are
          entirely the student's own work.</em></p>
        ")
          )
      ),
      
      div(class = "footer",
          "Click any county for details  ·  White = low rate → dark red = high rate  ·  Gray = no data"
      )
  )
)

# ── Server ────────────────────────────────────────────────────────────────────
server <- function(input, output, session) {
  
  map_data <- reactive({
    yr <- input$year
    stats_yr <- county_lead %>%
      filter(Year == yr) %>%
      select(County.FIPS, Rate_per_1000, Total_Tests, Total_Elevated)
    ny_counties_geo %>%
      left_join(stats_yr, by = c("FIPS_5" = "County.FIPS"))
  })
  
  global_pal <- make_pal(range(county_lead$Rate_per_1000, na.rm = TRUE))
  
  output$map <- renderLeaflet({
    leaflet() %>%
      addProviderTiles(providers$CartoDB.Positron) %>%
      setView(lng = -75.5, lat = 42.9, zoom = 7)
  })
  
  observe({
    data <- map_data()
    pal  <- global_pal
    leafletProxy("map", data = data) %>%
      clearShapes() %>%
      clearControls() %>%
      addPolygons(
        fillColor    = ~pal(Rate_per_1000),
        fillOpacity  = 0.82,
        color        = "#6b4a4a",
        weight       = 0.8,
        opacity      = 0.6,
        highlightOptions = highlightOptions(
          weight      = 2.5,
          color       = "#a50f15",
          fillOpacity = 0.95,
          bringToFront = TRUE
        ),
        label   = ~paste0(NAME, ": ", round(Rate_per_1000, 1), " per 1,000"),
        layerId = ~NAME
      ) %>%
      addLegend(
        pal      = pal,
        values   = ~Rate_per_1000,
        title    = "Rate per 1,000<br>children tested",
        position = "bottomright",
        opacity  = 0.85
      )
  })
  
  clicked_county <- reactiveVal(NULL)
  observeEvent(input$map_shape_click, {
    clicked_county(input$map_shape_click$id)
  })
  
  output$county_info <- renderUI({
    county <- clicked_county()
    if (is.null(county)) {
      return(HTML("<span style='color:#aaa;'>Click a county on the map to see details.</span>"))
    }
    row <- map_data() %>%
      st_drop_geometry() %>%
      filter(NAME == county)
    if (nrow(row) == 0 || is.na(row$Rate_per_1000)) {
      return(HTML(paste0("<b>", county, " County</b>: No data for ", input$year, ".")))
    }
    HTML(paste0(
      "<span class='info-label'>County:</span> ", county, " &emsp; ",
      "<span class='info-label'>Year:</span> ", input$year, "<br>",
      "<span class='info-label'>Children Tested:</span> ",
      formatC(row$Total_Tests, format = "d", big.mark = ","), " &emsp; ",
      "<span class='info-label'>Elevated Cases:</span> ",
      formatC(row$Total_Elevated, format = "d", big.mark = ","), "<br>",
      "<span class='info-label'>Rate per 1,000:</span> ",
      "<span class='big-rate'>", round(row$Rate_per_1000, 1), "</span>"
    ))
  })
}

# ── Launch ────────────────────────────────────────────────────────────────────
shinyApp(ui, server)